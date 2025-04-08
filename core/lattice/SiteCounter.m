classdef SiteCounter < BaseComputer

    properties (Constant)
        LatCalib_DefaultPath = "calibration/LatCalib.mat"
        PSFCalib_DefaultPath = "calibration/PSFCalib.mat"
        Count_CalibMode = "offset"
        Count_CountMethod = "center_signal"
        Count_ClassifyMethod = "single_threshold"
        Count_PlotDiagnostic = false
        Count_PlotIndex = 1
        Classify_SingleThreshold = 80
        CalibR_CropSites = 20
        CircleSum_SiteCircleRadius = 2
        SpreadMatrix_XRange = -30: 0.1: 30
        SpreadMatrix_YRange = -30: 0.1: 30
        SpreadMatrix_Sites = SiteGrid.prepareSite('Hex', 'latr', 2)
        SpreadMatrix_EdgePSFVal_WarnThreshold = 0.05
        SpreadMatrix_PSFRadius = 3.5
        DeconvWeight_XRange = 1: 1024
        DeconvWeight_YRange = 1: 1024
        DeconvWeight_Threshold = 0.01
        ReconstructSignal_XRange = []
        ReconstructSignal_YRange = []
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
        SpreadMatrix
        SpreadSites
        SpreadPixels
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

        function stat = process(obj, signal, num_frames, opt, opt1, opt2, opt3)
            arguments
                obj
                signal
                num_frames = 1
                opt.calib_mode = obj.Count_CalibMode
                opt.count_method = obj.Count_CountMethod
                opt.classify_method = obj.Count_ClassifyMethod
                opt.plot_diagnostic = obj.Count_PlotDiagnostic
                opt.plot_index = obj.Count_PlotIndex
                opt1.calib_crop_R_sites = obj.CalibR_CropSites
                opt2.site_circle_radius = obj.CircleSum_SiteCircleRadius
                opt3.single_threshold = obj.Classify_SingleThreshold
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
        
        % Update the class properties to a new calibration (Lat or PS)
        function updateSiteProp(obj, opt1, opt2)
            arguments
                obj 
                opt1.site_circle_radius = obj.CircleSum_SiteCircleRadius
                opt2.spread_sites = obj.SpreadMatrix_Sites
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius
                opt2.spread_center = [0, 0]
            end
            if isempty(obj.Lattice)
                return
            end
            obj.SiteCenters = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
            % Update properties related to count method "circle_sum"
            r = opt1.site_circle_radius;
            [Y, X] = meshgrid(-r:r, -r:r);
            idx = X(:).^2 + Y(:).^2 <= r^2;
            X = X(idx);
            Y = Y(idx);
            obj.SiteCircleX = round(obj.SiteCenters(:, 1) + X');
            obj.SiteCircleY = round(obj.SiteCenters(:, 2) + Y');
            % Update properties related to count method "linear_inverse"
        end
        
        % Generate a spread matrix of size (num_sites, num_pixels)
        % Each entry is the fraction of the signal from 1 site to 1 pixel
        function [M, x_range, y_range] = getSpreadMatrix(obj, opt2)
            arguments
                obj
                opt2.spread_sites = obj.SpreadMatrix_Sites
                opt2.spread_center = [0, 0]
                opt2.spread_xrange = obj.SpreadMatrix_XRange
                opt2.spread_yrange = obj.SpreadMatrix_YRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * obj.PointSource.RayleighResolution
            end
            Lat = obj.Lattice;
            PS = obj.PointSource;
            x_range = opt2.spread_xrange;
            y_range = opt2.spread_yrange;
            num_sites = height(opt2.spread_sites);
            num_px = length(x_range) * length(y_range);
            x_step = x_range(2) - x_range(1);
            y_step = y_range(2) - y_range(1);
            M = zeros(num_sites, num_px);
            if PS.PSFNormalized(x_range(1), y_range(1)) > opt2.spread_psf_warn_threshold
                obj.warn('PSF value at edge is significant: %.2f, please consider setting a different radius.')
            end
            for site_i = 1: num_sites
                center = opt2.spread_sites(site_i, :) * Lat.V + opt2.spread_center;
                center_xidx = (center(1) - x_range(1)) / x_step + 1;
                center_yidx = (center(2) - y_range(1)) / y_step + 1;
                min_xidx = max(1, round(center_xidx - opt2.spread_psf_radius / x_step));
                max_xidx = min(length(x_range), round(center_xidx + opt2.spread_psf_radius / x_step));
                min_yidx = max(1, round(center_yidx - opt2.spread_psf_radius / y_step));
                max_yidx = min(length(y_range), round(center_yidx + opt2.spread_psf_radius / y_step));
                xidx = min_xidx : max_xidx;
                yidx = min_yidx : max_yidx;
                idx = xidx' + (yidx - 1) * length(x_range);
                [YP,XP] = meshgrid(y_range(yidx), x_range(xidx));
                M(site_i, idx) = PS.PSFNormalized(XP(:) - center(1), YP(:) - center(2)) * x_step * y_step;
            end
        end
        
        % Generate a function handle to de-convolution pattern
        function [func, pat, x_range, y_range] = getDeconvFunc(obj, varargin)
            [M, x_range, y_range] = obj.getSpreadMatrix(varargin{:});
            Minv = (M * M') \ M;
            num_sites = size(M, 1);
            pat = reshape(Minv(ceil(num_sites / 2), :), length(x_range), length(y_range));
            [Y, X] = meshgrid(y_range, x_range);
            func = @deconvFunc;
            function val = deconvFunc(x, y)
                val = interp2(Y, X, pat, y, x);
                val(isnan(val)) = 0;
            end
        end

        % Generate a list of pixel weights for each site from a deconv func
        function weights = getDeconvWeight(obj, opt1, opt2)
            arguments
                obj
                opt1.radius = obj.SpreadMatrix_PSFRadius * obj.PointSource.RayleighResolution
                opt1.x_range = obj.DeconvWeight_XRange
                opt1.y_range = obj.DeconvWeight_YRange
                opt1.threshold = obj.DeconvWeight_Threshold
                opt2.spread_sites = obj.SpreadMatrix_Sites
                opt2.spread_center = [0, 0]
                opt2.spread_xrange = obj.SpreadMatrix_XRange
                opt2.spread_yrange = obj.SpreadMatrix_YRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * obj.PointSource.RayleighResolution
            end
            args = namedargs2cell(opt2);
            func = obj.getDeconvFunc(args{:});
            x_step = opt1.x_range(2) - opt1.x_range(1);
            y_step = opt1.y_range(2) - opt1.y_range(1);
            centers = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
            weights = cell(1, size(centers, 1));
            for site_i = 1: size(centers, 1)
                center = centers(site_i, :);
                xmin = max(opt1.x_range(1), round(center(1)) - opt1.radius(1));
                xmax = min(opt1.x_range(end), round(center(1)) + opt1.radius(1));
                ymin = max(opt1.y_range(1), round(center(2)) - opt1.radius(end));
                ymax = min(opt1.y_range(end), round(center(2) + opt1.radius(end)));
                xidx = ((xmin: xmax) - opt1.x_range(1)) / x_step;
                yidx = ((ymin: ymax) - opt1.y_range(1)) / y_step;
                idx = xidx' + (yidx - 1) * length(opt1.x_range);
                [YP, XP] = meshgrid((ymin:ymax) - center(2), (xmin:xmax) - center(1));
                val = func(XP(:), YP(:));
                keep = abs(val) > opt1.threshold;
                weights{site_i} = [idx(keep), val(keep)];
            end
        end
        
        % Generate a simulated image given the counts on the sites
        function [reconstructed, x_range, y_range] = reconstructSignal(obj, sites, counts, opt2)
            arguments
                obj
                sites
                counts
                opt2.spread_xrange = obj.ReconstructSignal_XRange
                opt2.spread_yrange = obj.ReconstructSignal_YRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * obj.PointSource.RayleighResolution
            end
            if isempty(opt2.spread_xrange) || isempty(opt2.spread_yrange)
                centers = obj.Lattice.convert2Real(sites);
                xmin = max(1, round(min(centers(:, 1))));
                xmax = round(max(centers(:, 1)));
                ymin = max(1, round(min(centers(:, 2))));
                ymax = round(max(centers(:, 2)));
                opt2.spread_xrange = xmin : xmax;
                opt2.spread_yrange = ymin : ymax;
            end
            args = namedargs2cell(opt2);
            [M, x_range, y_range] = obj.getSpreadMatrix('spread_sites', sites, 'spread_center', obj.Lattice.R, args{:});
            reconstructed = reshape(M' * counts, length(x_range), length(y_range));
        end
    end

    methods (Static)
        function description = describe(stat, options)
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

%% Get adaptive thresholds to classify 0 and 1 from counts distribution
function thresholds = getThreshold(counts)
end

%% Utility functions
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
        lat.plotOccup(sites(occup(:, j), :), sites(~occup(:, j), :), ...
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
