classdef SiteCounter < BaseComputer

    properties (Constant)
        LatCalib_DefaultPath = "calibration/LatCalib.mat"
        PSFCalib_DefaultPath = "calibration/PSFCalib.mat"
        Count_CalibMode = "offset"
        Count_CountMethod = "center_signal"
        Count_ClassifyMethod = "single_threshold"
        Count_SingleThreshold = 80
        Count_SiteCircleRadius = 2
        Count_PlotDiagnostic = false
    end

    properties (SetAccess = immutable)
        SiteGrid
        PointSource
        Lattice
    end

    properties (SetAccess = protected)
        SiteCenters
        SiteCircleX
        SiteCircleY
        TransformMatrix
        DeconvPattern
    end
    
    methods
        function obj = SiteCounter(id, lat, ps, grid)
            arguments
                id = "Andor19330"
                lat = []
                ps = []
                grid = SiteGrid()
            end
            obj@BaseComputer(id)
            if isempty(lat)
                try
                    obj.Lattice = load(obj.LatCalib_DefaultPath).(id);
                catch
                    obj.error("No lattice calibration provided!")
                    obj.Lattice = [];
                end
            end
            if isempty(ps)
                try
                    obj.PointSource = load(obj.PSFCalib_DefaultPath).(id);
                catch
                    obj.warn("No PSF calibration provided!")
                    obj.PointSource = [];
                end
            end
            obj.SiteGrid = grid;
            obj.updateSiteProp()
        end

        function stat = count(obj, signal, x_range, y_range, opt, opt1)
            arguments
                obj
                signal
                x_range = 1: size(signal, 1)
                y_range = 1: size(signal, 2)
                opt.calib_mode = obj.Count_CalibMode
                opt.count_method = obj.Count_CountMethod
                opt.classify_method = obj.Count_ClassifyMethod
                opt.single_threshold = obj.Count_SingleThreshold
                opt.plot_diagnostic = obj.Count_PlotDiagnostic
                opt1.site_circle_radius = obj.Count_SiteCircleRadius
            end
            switch opt.calib_mode
                case "full"
                    obj.Lattice.calibrate(signal, x_range, y_range)
                    args = namedargs2cell(opt1);
                    obj.updateSiteProp(args{:})
                case "offset"
                    obj.Lattice.calibrateR(signal, x_range, y_range)
                    args = namedargs2cell(opt1);
                    obj.updateSiteProp(args{:})
                case "none"
                otherwise
                    obj.error("Unsupported calibration mode: %s!", opt.calib_mode)
            end
            stat.SiteInfo = obj.SiteGrid.struct(obj.SiteGrid.VisibleProp);
            stat.SiteInfo.CountMethod = opt.count_method;
            stat.SiteInfo.CalibMode = opt.calib_mode;
            switch opt.count_method
                case "center_signal"
                    stat = getCount_CenterSignal(obj, stat, signal, x_range, y_range);
                case "circle_sum"
                    stat = getCount_CircleSum(obj, stat, signal, x_range, y_range);
                case "linear_inverse"
                    stat = getCount_LinearInverse(obj, stat, signal, x_range, y_range);
                otherwise
                    obj.error('Unsupported counting method: %s!', opt.count_method)
            end
            switch opt.classify_method
                case "single_threshold"
                    stat.LatOccup = getOccup_SingleThreshold(stat.LatCount, opt.single_threshold);
                otherwise
                    obj.error('Unsupported classification method: %s!', opt.classify_method)
            end
            if opt.plot_diagnostic
                plotCountsDiagnostic(stat, signal, x_range, y_range, obj.Lattice)
            end
        end

        function updateSiteProp(obj, options)
            arguments
                obj 
                options.site_circle_radius = obj.Count_SiteCircleRadius
            end
            if isempty(obj.Lattice)
                return
            end
            obj.SiteCenters = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
            r = options.site_circle_radius;
            [Y, X] = meshgrid(-r:r, -r:r);
            idx = X(:).^2 + Y(:).^2 <= r^2;
            X = X(idx);
            Y = Y(idx);
            obj.SiteCircleX = round(obj.SiteCenters(:, 1) + X');
            obj.SiteCircleY = round(obj.SiteCenters(:, 2) + Y');
        end
    end

end

%% Functions to extract site counts from signal image
function stat = getCount_CenterSignal(obj, stat, signal, x_range, y_range)
    site_centers = round(obj.SiteCenters);
    index = site_centers(:, 1) - x_range(1) + (site_centers(:, 2) - y_range(1)) * length(x_range);
    stat.LatCount = signal(index);
end

function stat = getCount_CircleSum(obj, stat, signal, x_range, y_range)
    index = obj.SiteCircleX - x_range(1) + (obj.SiteCircleY - y_range(1)) * length(x_range);
    stat.LatCount = sum(reshape(signal(index), size(obj.SiteCircleX)), 2);
end

function stat = getCount_LinearInverse(obj, stat, signal, x_range, y_range)    
end

%% Functions to extract occupancies from counts
function occup = getOccup_SingleThreshold(counts, threshold)
    occup = counts > threshold;
end

%%
function plotCountsDiagnostic(stat, signal, x_range, y_range, lat)
    figure('Name', 'Diagnostic plots for counts reconstruction')
    subplot(1, 2, 1)
    imagesc2(y_range, x_range, signal)
    lat.plot(stat.SiteInfo.Sites)
    lat.plotV()
    title('Signal')
    subplot(1, 2, 2)
    lat.plotCounts(stat.SiteInfo.Sites, stat.LatCount, 'filter', true, ...
        'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
    hold on
    lat.plotV()
    title('Counts')
end

function Count = getCount(Signal,XStart,Deconv)
    XPixels = size(Signal,1);
    NumSite = size(Deconv,1);
    NumSubImg = size(XStart,1);
    Count = zeros(NumSite,NumSubImg);

    for i = 1:NumSite
        List = Deconv{i,1}+XPixels*(Deconv{i,2}-1);
        if size(List,1)>0
            for j = 1:NumSubImg
                Count(i,j) = Deconv{i,3}'*Signal(List+XStart(j)-1); %only
                %line in original code
%                 Count(i,j) = ones(size(Deconv{i,3}'))*Signal(List+XStart(j)-1);
            end
        end
    end
end

function  [Deconv,DecPat] = getDeconv(Lat,funcPSF,Site,XLim,YLim)
    
    % Default deconvolution parameters
    PSFR = 10;
    RPattern = 30;
    Factor = 5;
    LatRLim = 2;
    RDeconv = 15;
    Threshold = 0.01;
    
    % Initialize
    NumSite = size(Site,1);
    Deconv = cell(NumSite,3);
    
    % Get the deconvolution pattern
    DecPat = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim);
    %DecPat = ones(size(DecPat));
    %DecPat = DecPat/sum(DecPat,"all");
    
    % For each lattice site, find corresponding pixels and weights
    for i = 1:NumSite

        % Convert lattice X-Y index to CCD space coordinates
        Center = Site(i,:)*Lat.V+Lat.R;
        
        % Find X and Y range of pixels
        CX = round(Center(1));
        CY = round(Center(2));

        XMin = max(CX-RDeconv,1);
        XMax = min(CX+RDeconv,XLim);
        YMin = max(CY-RDeconv,1);
        YMax = min(CY+RDeconv,YLim);
        
        % Generate a list of pixel coordinates
        [Y,X] = meshgrid(YMin:YMax,XMin:XMax);
        XList = X(:);
        YList = Y(:);
        
        % Find the distance to site center
        XDis = XList-Center(1);
        YDis = YList-Center(2);
       
        % Find the cooresponding index in the deconvolution pattern
        XDeconv = round(Factor*(XDis+RPattern))+1;
        YDeconv = round(Factor*(YDis+RPattern))+1;
        XYDeconv = XDeconv+(YDeconv-1)*(2*Factor*RPattern+1);
        
        % Assign weights
        WeightList = DecPat(XYDeconv);
        Index = abs(WeightList)>Threshold;     
        Deconv{i,1} = XList(Index);
        Deconv{i,2} = YList(Index);
        Deconv{i,3} = WeightList(Index);
    end
    
end

function Pattern = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim)
% Calculate deconvolution pattern by inverting (-LatRLim:LatRLim) PSF

    % Number of sites
    NumSite = (2*LatRLim+1)^2;

    % Number of pixels
    NumPx = (2*Factor*RPattern+1)^2;

    M = zeros(NumSite,NumPx);
    if funcPSF(PSFR,PSFR)>0.001
        warning(['Probability density at edge is significant = %.4f\nCheck' ...
            ' PSFR (radius for calculating PSF spread)'],funcPSF(PSFR,PSFR))
    end
    
    % For each lattice site, find its spread into nearby pixels
    for i = -LatRLim:LatRLim
        for j = -LatRLim:LatRLim
            
            % Site index
            Site = (i+LatRLim+1)+(j+LatRLim)*(2*LatRLim+1);

            % Lattice site coordinate
            Center = [i,j]*Lat.V;

            % Convert coordinate to magnified pixel index
            CXIndex = round(Factor*(Center(1)+RPattern))+1;
            CYIndex = round(Factor*(Center(2)+RPattern))+1;

            % Range of pixel index to run through
            xMin = CXIndex-PSFR*Factor;
            xMax = CXIndex+PSFR*Factor;
            yMin = CYIndex-PSFR*Factor;
            yMax = CYIndex+PSFR*Factor;

            % Go through all pixels and assign the spread
            x = xMin:xMax;
            y = yMin:yMax;
            Pixel = x'+(y-1)*(2*Factor*RPattern+1);
            [YP,XP] = meshgrid((y-1)/Factor-RPattern,(x-1)/Factor-RPattern);
            M(Site,Pixel) = funcPSF(XP(:)-Center(1),YP(:)-Center(2))/Factor^2;
            
        end
    end

    % Convert transfer matrix to deconvolution pattern
    MInv = (M*M')\M;
    Pattern = reshape(MInv(round(NumSite/2),:),sqrt(NumPx),[]);

    % Re-normalize deconvolution pattern
    Area = abs(det(Lat.V));
    %disp(Area);
    Pattern = Area/(sum(Pattern,"all")/Factor^2)*Pattern;
    %Pattern= Pattern/sum(Pattern,"all");
end

