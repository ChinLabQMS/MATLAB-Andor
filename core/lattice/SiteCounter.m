classdef SiteCounter < BaseComputer

    properties (Constant)
        LatCalib_DefaultPath = "calibration/LatCalib.mat"
        PSFCalib_DefaultPath = "calibration/PSFCalib.mat"
        Count_CalibMode = "offset"
        Count_CountMethod = "center_signal"
        Count_ClassifyMethod = "single_threshold"
        Count_PlotDiagnostic = false
        Count_PlotIndex = 1
        Count_SingleThreshold = 80
        Count_SiteCircleRadius = 2
        Count_CalibRCropSites = 20
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
            else
                obj.Lattice = lat;
            end
            if isempty(ps)
                try
                    obj.PointSource = load(obj.PSFCalib_DefaultPath).(id);
                catch
                    obj.warn("No PSF calibration provided!")
                    obj.PointSource = [];
                end
            else
                obj.PointSource = ps;
            end
            obj.SiteGrid = grid;
            obj.updateSiteProp()
        end

        function stat = count(obj, signal, num_frames, opt, opt1, opt2, opt3)
            arguments
                obj
                signal
                num_frames = 1
                opt.calib_mode = obj.Count_CalibMode
                opt.count_method = obj.Count_CountMethod
                opt.classify_method = obj.Count_ClassifyMethod
                opt.plot_diagnostic = obj.Count_PlotDiagnostic
                opt.plot_index = obj.Count_PlotIndex
                opt1.calib_crop_R_sites = obj.Count_CalibRCropSites
                opt2.site_circle_radius = obj.Count_SiteCircleRadius
                opt3.single_threshold = obj.Count_SingleThreshold
            end
            [x_size, y_size, num_acq] = size(signal, [1, 2, 3]);
            x_range = 1: (x_size / num_frames);
            y_range = 1: y_size;
            % Calibrate lattice center offset, or use the existing Lat.R
            args = namedargs2cell(opt2);
            switch opt.calib_mode
                case "offset"
                    signal_sum = getSignalSum(signal, num_frames, "first_only", false);
                    obj.Lattice.calibrateRCropSite(signal_sum, opt1.calib_crop_R_sites)
                    obj.updateSiteProp(args{:})
                case "offset_every"
                case "none"
                otherwise
                    obj.error("Unsupported calibration mode: %s!", opt.calib_mode)
            end
            % Initialize result stat structure
            stat.SiteInfo = obj.SiteGrid.struct(obj.SiteGrid.VisibleProp);
            stat.SiteInfo.CountMethod = opt.count_method;
            stat.SiteInfo.CalibMode = opt.calib_mode;
            stat.LatCount = nan(obj.SiteGrid.NumSites, num_frames, num_acq);
            stat.LatOccup = nan(obj.SiteGrid.NumSites, num_frames, num_acq);
            % Get site-wise counts for each acquisition and sub-frame
            for i = 1: num_acq
                single_shot = signal(:, :, i);
                if opt.calib_mode == "offset_every"
                    signal_sum = getSignalSum(single_shot, num_frames, 'first_only', false);
                    obj.Lattice.calibrateRCropSite(signal_sum, opt1.calib_crop_R_sites)
                    obj.updateSiteProp(args{:})
                end
                x_range_all = x_range + ((x_size/num_frames) .* (0: (num_frames -1)))';
                for j = 1: num_frames
                    xf_range = x_range_all(j, :);
                    single_frame = single_shot(xf_range, y_range);
                    switch opt.count_method
                        case "center_signal"
                            stat.LatCount(:, j, i) = getCount_CenterSignal(obj, single_frame, x_range, y_range);
                        case "circle_sum"
                            stat.LatCount(:, j, i) = getCount_CircleSum(obj, single_frame, x_range, y_range);
                        case "linear_inverse"
                            stat.LatCount(:, j, i) = getCount_LinearInverse(obj, single_frame, x_range, y_range);
                        otherwise
                            obj.error('Unsupported counting method: %s!', opt.count_method)
                    end
                end
            end
            % Classify sites as occupied/unoccupied
            switch opt.classify_method
                case "single_threshold"
                    stat.LatOccup = getOccup_SingleThreshold(stat.LatCount, opt3.single_threshold);
                case "adaptive_threshold"
                    thresholds = getThreshold(stat.LatCount);
                    stat.LatOccup = getOccup_SingleThreshold(stat.LatCount, thresholds);
                otherwise
                    obj.error('Unsupported classification method: %s!', opt.classify_method)
            end
            if opt.plot_diagnostic
                plotCountsDiagnostic(obj.Lattice, stat, signal, num_frames, opt.plot_index)
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
            % Update properties related to count method "circle_sum"
            r = options.site_circle_radius;
            [Y, X] = meshgrid(-r:r, -r:r);
            idx = X(:).^2 + Y(:).^2 <= r^2;
            X = X(idx);
            Y = Y(idx);
            obj.SiteCircleX = round(obj.SiteCenters(:, 1) + X');
            obj.SiteCircleY = round(obj.SiteCenters(:, 2) + Y');
            % Update properties related to count method "linear_inverse"
        end
    end

    methods (Static)
        function stat_diag = getDiagStat(stat, options)
            arguments
                stat
                options.verbose = true
            end
            
        end
    end
end

%% Functions to extract site counts from signal image
function counts = getCount_CenterSignal(obj, signal, x_range, y_range)
    site_centers = round(obj.SiteCenters);
    index = site_centers(:, 1) - x_range(1) + (site_centers(:, 2) - y_range(1)) * length(x_range);
    counts = signal(index);
end

function counts = getCount_CircleSum(obj, signal, x_range, y_range)
    index = obj.SiteCircleX - x_range(1) + (obj.SiteCircleY - y_range(1)) * length(x_range);
    counts = sum(reshape(signal(index), size(obj.SiteCircleX)), 2);
end

function counts = getCount_LinearInverse(obj, signal, x_range, y_range)
end

%% Functions to extract occupancy from counts
function occup = getOccup_SingleThreshold(counts, threshold)
    occup = counts > threshold;
end

%% Get thresholds to classify 0 and 1 from counts distribution
function thresholds = getThreshold(counts)
end

%%
function plotCountsDiagnostic(lat, stat, signal, num_frames, index)
    signal = signal(:, :, index);
    sites = stat.SiteInfo.Sites;
    counts = stat.LatCount(:, :, index);
    occup = stat.LatOccup(:, :, index);
    [x_size, y_size] = size(signal);
    centers = lat.R + (0: (num_frames - 1))' .* [(x_size / num_frames), 0];
    figure('Name', 'Diagnostic plots for counts reconstruction')
    subplot(1, 2, 1)
    imagesc2(signal)
    for j = 1: num_frames
        lat.plotOccup(sites(occup(:, j), :), zeros(0, 2), ...
            'center', centers(j, :), 'filter', true, ...
            'x_lim', [0, x_size], 'y_lim', [0, y_size])
    end
    lat.plotV('center', centers)
    title('Signal')
    subplot(1, 2, 2)
    lat.plotCounts(stat.SiteInfo.Sites, counts(:, 1), ...
            'center', centers(1, :), 'filter', true, ...
            'x_lim', [0, x_size], 'y_lim', [0, y_size], ...
            'add_background', true, 'fill_sites', false)
    for j = 2: num_frames
        lat.plotCounts(stat.SiteInfo.Sites, stat.LatCount(:, j, index), ...
            'center', centers(j, :), 'filter', true, ...
            'x_lim', [0, x_size], 'y_lim', [0, y_size], ...
            'add_background', false, 'fill_sites', false)
    end
    lat.plotV('center', centers)
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

