classdef SiteCounter < BaseComputer

    properties (Constant)
        LatCalib_DefaultPath = "calibration/LatCalib.mat"
        PSFCalib_DefaultPath = "calibration/PSFCalib.mat"
        Count_CalibMode = "offset"
        Count_CountMethod = "center_signal"
        Count_ClassifyMethod = "single_threshold"
        Count_PlotDiagnostic = false
    end

    properties (SetAccess = immutable)
        SiteGrid
        PointSource
        Lattice
    end

    properties (SetAccess = protected)
        SiteCenters
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
            obj.updateSiteCenters()
        end

        function stat = count(obj, signal, x_range, y_range, options)
            arguments
                obj
                signal
                x_range = 1: size(signal, 1)
                y_range = 1: size(signal, 2)
                options.count_method = obj.Count_CountMethod
                options.classify_method = obj.Count_ClassifyMethod
                options.calib_mode = obj.Count_CalibMode
                options.plot_diagnostic = obj.Count_PlotDiagnostic
            end
            switch options.calib_mode
                case "full"
                    obj.Lattice.calibrate(signal, x_range, y_range)
                    obj.updateSiteCenters()
                case "offset"
                    obj.Lattice.calibrateR(signal, x_range, y_range)
                    obj.updateSiteCenters()
                case "none"
                otherwise
                    obj.error("Unsupported calibration mode: %s!", options.calib_mode)
            end
            stat.SiteInfo = obj.SiteGrid.struct(obj.SiteGrid.VisibleProp);
            stat.SiteInfo.SiteCenters = obj.SiteCenters;
            stat.SiteInfo.CountMethod = options.count_method;
            stat.SiteInfo.CalibMode = options.calib_mode;
            switch options.count_method
                case "center_signal"
                    stat = getCount_CenterSignal(stat, signal, x_range, y_range);
                case "circle_sum"
                    stat = getCount_CircleSum(stat, signal, x_range, y_range);
                case "linear_inverse"
                    stat = getCount_LinearInverse(stat, signal, x_range, y_range);
                otherwise
                    obj.error('Unsupported counting method: %s!', options.count_method)
            end
            switch options.classify_method
                case "single_threshold"
                otherwise
                    obj.error('Unsupported classification method: %s!', options.classify_method)
            end
            if options.plot_diagnostic
                plotDiagnostic(stat, signal, x_range, y_range, obj.Lattice)
            end
        end

        function updateSiteCenters(obj)
            if ~isempty(obj.Lattice)
                obj.SiteCenters = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
            end
        end
    end

end

%% Functions to extract site counts from signal image
function stat = getCount_CenterSignal(stat, signal, x_range, y_range)
    site_centers = round(stat.SiteInfo.SiteCenters);
    index = site_centers(:, 1) - x_range(1) + (site_centers(:, 2) - y_range(1)) * length(x_range);
    stat.LatCount = signal(index);
end

function stat = getCount_CircleSum(stat, signal, x_range, y_range)
    
end

function stat = getCount_LinearInverse(stat, signal, x_range, y_range)
    
end

%%
function plotDiagnostic(stat, signal, x_range, y_range, lat)
    figure
    subplot(1, 2, 1)
    imagesc2(y_range, x_range, signal)
    lat.plot(stat.SiteInfo.Sites)
    lat.plotV()
    title('Signal')
    limts = clim();
    subplot(1, 2, 2)
    lat.plotCounts(stat.SiteInfo.Sites, stat.LatCount, 'filter', true, ...
        'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
    hold on
    lat.plotV()
    title('Counts')
    clim(limts)
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

