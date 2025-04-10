classdef SiteCounter < BaseComputer

    properties (Constant)
        LatCalib_DefaultPath = "calibration/LatCalib.mat"
        PSFCalib_DefaultPath = "calibration/PSFCalib.mat"
        Process_CalibMode = "offset"
        Process_CountMethod = "linear_inverse"
        Process_ClassifyMethod = "single"
        Process_AddDescription = true
        Process_PlotDiagnostic = false
        Process_PlotDiagnosticIndex = 1
        ProcessCalib_CropRSites = 20
        ProcessClassify_SingleThreshold = 1200
        CountCircleSum_SiteCircleRadius = 2
        SpreadMatrix_Center = [0, 0]
        SpreadMatrix_Sites = SiteGrid.prepareSite('Hex', 'latr', 2)
        SpreadMatrix_XRange = -30: 0.1: 30
        SpreadMatrix_YRange = -30: 0.1: 30
        SpreadMatrix_EdgePSFVal_WarnThreshold = 0.05
        SpreadMatrix_PSFRadius = 2.6
        SpreadMatrix_Sparse = true
        DeconvWeight_XRange = 1: 1024
        DeconvWeight_YRange = 1: 1024
        DeconvWeight_Threshold = 0.01
    end

    properties (SetAccess = immutable)
        SiteGrid
        PointSource
        Lattice
    end

    properties (SetAccess = protected)
        SignalXRange = []
        SignalYRange = []
        SiteCenters
        SpreadMatrix
        SiteCircleX
        SiteCircleY
        DeconvFunc
        DeconvWeight  % Sparse matrix to store pixel weights for each site
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
        
        % Main interface for app and analysis
        function stat = process(obj, signal, num_frames, opt, opt1, opt2)
            arguments
                obj
                signal
                num_frames = 1
                % Parameters on the entire flow
                opt.calib_mode = obj.Process_CalibMode
                opt.calib_cropRsites = obj.ProcessCalib_CropRSites
                opt.count_method = obj.Process_CountMethod
                opt1.classify_method = obj.Process_ClassifyMethod
                opt1.classify_threshold = obj.ProcessClassify_SingleThreshold
                opt2.add_description = obj.Process_AddDescription
                opt2.plot_diagnostic = obj.Process_PlotDiagnostic
                opt2.plot_index = obj.Process_PlotDiagnosticIndex
            end
            [x_size, y_size, num_acq] = size(signal, [1, 2, 3]);
            x_range = 1: (x_size / num_frames);
            y_range = 1: y_size;
            % Initialize result stat structure
            stat.SiteInfo = obj.SiteGrid.struct(obj.SiteGrid.VisibleProp);
            stat.SiteInfo.CountMethod = opt.count_method;
            stat.SiteInfo.CalibMode = opt.calib_mode;
            stat.LatCount = nan(obj.SiteGrid.NumSites, num_frames, num_acq);
            stat.LatOccup = nan(obj.SiteGrid.NumSites, num_frames, num_acq);
            % Calibrate lattice center offset, or use the existing Lat.R
            args = namedargs2cell(opt);
            obj.precalibrate(signal, num_frames, args{:})
            % Get site-wise counts for each acquisition and sub-frame
            for i = 1: num_acq
                single_shot = signal(:, :, i);
                switch opt.calib_mode
                    case {"offset_every", "full_first_offset_every"}
                        signal_sum = getSignalSum(single_shot, num_frames, 'first_only', false);
                        obj.Lattice.calibrateRCropSite(signal_sum, opt.calib_cropRsites)
                        obj.updateSiteProp(x_range, y_range, opt.count_method)
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
            switch opt1.classify_method
                case "single"
                    stat.LatThreshold = opt1.classify_threshold;
                    stat.LatOccup = getOccup_SingleThreshold(stat.LatCount, opt1.classify_threshold);
                case "pre-loaded"
                case "gmm"
                    % Use a two component Gaussian mixture model to fit the counts distribution
                    [stat.LatOccup, stat.LatProb, stat.LatThreshold, stat.GMModel] = getOccup_GMMThreshold(stat.LatCount);
                case "none"
                otherwise
                    obj.error('Unsupported classification method: %s!', opt.classify_method)
            end
            if opt2.add_description && ~(opt1.classify_method == "none")
                stat.Description = obj.describe(stat.LatOccup);
            end
            if opt2.plot_diagnostic
                plotCountsDiagnostic(obj, stat, signal, num_frames, opt2.plot_index)
            end
        end

        function precalibrate(obj, signal, num_frames, opt)
            arguments
                obj
                signal
                num_frames
                opt.calib_mode = obj.Process_CalibMode
                opt.calib_cropRsites = obj.ProcessCalib_CropRSites
                opt.count_method = obj.Process_CountMethod
            end
            [x_size, y_size, ~] = size(signal, [1, 2, 3]);
            x_range = 1: (x_size / num_frames);
            y_range = 1: y_size;
            switch opt.calib_mode
                case {"full", "full_first_offset_every"}
                    obj.info('Starting full calibration...')
                    old_lat = obj.Lattice.copy();
                    signal_sum = getSignalSum(signal, num_frames, "first_only", false);
                    [xc, yc] = fitGaussXY(signal_sum, x_range, y_range);
                    obj.Lattice.init([xc, yc], 'format', 'R')
                    obj.Lattice.calibrateCropSite(signal_sum, opt.calib_cropRsites)
                    obj.Lattice.checkDiff(old_lat, obj.Lattice)
                    obj.updateSiteProp(x_range, y_range, opt.count_method)
                case "offset"
                    signal_sum = getSignalSum(signal, num_frames, "first_only", false);
                    obj.Lattice.calibrateRCropSite(signal_sum, opt.calib_cropRsites)
                    obj.updateSiteProp(x_range, y_range, opt.count_method)
                case "update_range_only"
                    obj.updateSiteProp(x_range, y_range, opt.count_method)
                case "offset_every"
                case "none"
                    if isempty(obj.SignalXRange) || isempty(obj.SignalYRange)
                        obj.updateSiteProp(x_range, y_range, opt.count_method)
                    end
                otherwise
                    obj.error("Unsupported calibration mode: %s!", opt.calib_mode)
            end
        end
        
        % Update the class properties to a new calibration (Lat or PS)
        % depending on the counting methods
        function updateSiteProp(obj, x_range, y_range, count_method)
            arguments
                obj 
                x_range = []
                y_range = []
                count_method = obj.Process_CountMethod
            end
            if isempty(obj.Lattice)
                return
            end
            obj.SignalXRange = x_range;
            obj.SignalYRange = y_range;
            switch count_method
                case "circle_sum"
                    obj.SiteCenters = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
                    % Update properties related to count method "circle_sum"
                    r = obj.CountCircleSum_SiteCircleRadius;
                    [Y, X] = meshgrid(-r:r, -r:r);
                    idx = X(:).^2 + Y(:).^2 <= r^2;
                    X = X(idx);
                    Y = Y(idx);
                    obj.SiteCircleX = round(obj.SiteCenters(:, 1) + X');
                    obj.SiteCircleY = round(obj.SiteCenters(:, 2) + Y');
                case "linear_inverse"
                    [obj.DeconvWeight, obj.SiteCenters, obj.DeconvFunc] = ...
                        obj.getDeconvWeight();
            end
            if ~isempty(x_range) && ~isempty(y_range)
                obj.SpreadMatrix = obj.getSpreadMatrix( ...
                    "spread_center", obj.Lattice.R, ...
                    "spread_sites", obj.SiteGrid.Sites, ...
                    "spread_xrange", x_range, ...
                    "spread_yrange", y_range,  ...
                    "spread_sparse", true);
            end
        end
        
        % Generate a spread matrix of size (num_sites, num_pixels)
        % Each entry is the fraction of the signal from 1 site to 1 pixel
        function [M, x_range, y_range] = getSpreadMatrix(obj, opt2)
            arguments
                obj
                opt2.spread_center = obj.SpreadMatrix_Center
                opt2.spread_sites = obj.SpreadMatrix_Sites
                opt2.spread_xrange = obj.SpreadMatrix_XRange
                opt2.spread_yrange = obj.SpreadMatrix_YRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * ...
                        (obj.PointSource.RayleighResolution * obj.PointSource.InitResolutionRatio)
                opt2.spread_sparse = obj.SpreadMatrix_Sparse
            end
            Lat = obj.Lattice;
            PS = obj.PointSource;
            x_range = opt2.spread_xrange;
            y_range = opt2.spread_yrange;
            num_sites = height(opt2.spread_sites);
            num_px = length(x_range) * length(y_range);
            x_step = x_range(2) - x_range(1);
            y_step = y_range(2) - y_range(1);
            if opt2.spread_sparse
                M = sparse(num_sites, num_px);
            else
                M = zeros(num_sites, num_px);
            end
            if PS.PSFNormalized(opt2.spread_psf_radius, ...
                                opt2.spread_psf_radius) > opt2.spread_psf_warn_threshold
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
            [M, x_range, y_range] = obj.getSpreadMatrix(varargin{:}, 'spread_center', [0, 0]);
            Minv = (M * M') \ M;
            num_sites = size(M, 1);
            pat = full(reshape(Minv(ceil(num_sites / 2), :), length(x_range), length(y_range)));
            [Y, X] = meshgrid(y_range, x_range);
            func = @(x, y) interp2(Y, X, pat, y, x, "linear", 0);
        end

        % Generate a list of pixel weights for each site from a deconv func
        function [weights, centers, func, pat] = getDeconvWeight(obj, opt1, opt2)
            arguments
                obj
                opt1.radius = obj.SpreadMatrix_PSFRadius * ...
                        (obj.PointSource.RayleighResolution * obj.PointSource.InitResolutionRatio)
                opt1.signal_xrange = obj.SignalXRange
                opt1.signal_yrange = obj.SignalYRange
                opt1.threshold = obj.DeconvWeight_Threshold
                opt2.spread_sites = obj.SpreadMatrix_Sites
                opt2.spread_xrange = obj.SpreadMatrix_XRange
                opt2.spread_yrange = obj.SpreadMatrix_YRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * ...
                        (obj.PointSource.RayleighResolution * obj.PointSource.InitResolutionRatio)
                opt2.spread_sparse = obj.SpreadMatrix_Sparse
            end
            centers = obj.Lattice.convert2Real(obj.SiteGrid.Sites);
            x_range = opt1.signal_xrange;
            y_range = opt1.signal_yrange;
            if isempty(x_range) || isempty(y_range)
                weights = [];
                centers = [];
                func = [];
                pat = [];
                return
            end
            x_step = x_range(2) - x_range(1);
            y_step = y_range(2) - y_range(1);
            args = namedargs2cell(opt2);
            [func, pat] = obj.getDeconvFunc(args{:});
            num_sites = size(centers, 1);
            num_px = length(x_range) * length(y_range);
            weights = sparse(num_sites, num_px);
            for site_i = 1: size(centers, 1)
                center = centers(site_i, :);
                xmin = max(x_range(1), round(center(1) - opt1.radius(1)));
                xmax = min(x_range(end), round(center(1) + opt1.radius(1)));
                ymin = max(y_range(1), round(center(2) - opt1.radius(end)));
                ymax = min(y_range(end), round(center(2) + opt1.radius(end)));
                xidx = ((xmin: xmax) - x_range(1)) / x_step;
                yidx = ((ymin: ymax) - y_range(1)) / y_step;
                % linear index of the pixels for the given pixel ranges
                idx = xidx' + (yidx - 1) * length(x_range);
                [YP, XP] = meshgrid((ymin:ymax), (xmin:xmax));
                val = func(XP(:) - center(1), YP(:) - center(2)) * x_step * y_step;
                % filter index that has values larger than threshold
                keep = abs(val) > opt1.threshold;
                weights(site_i, idx(keep)) = val(keep); %#ok<SPRIX>
            end
        end

        function plotDeconvPattern(obj, ax, x_range, y_range)
            arguments
                obj
                ax = gca()
                x_range = obj.SpreadMatrix_XRange
                y_range = obj.SpreadMatrix_YRange
            end
            if isempty(obj.DeconvFunc)
                return
            end
            [Y, X] = meshgrid(y_range, x_range);
            pat = reshape(obj.DeconvFunc(X(:), Y(:)), length(x_range), length(y_range));
            imagesc2(ax, y_range, x_range, pat)
        end
        
        % Generate a simulated image given the counts on the sites
        function [reconstructed, x_range, y_range] = reconstructSignal(obj, counts, sites, opt1, opt2)
            arguments
                obj
                counts = []
                sites = obj.SiteGrid.Sites
                opt1.transform_matrix = obj.SpreadMatrix
                opt2.spread_xrange = obj.SignalXRange
                opt2.spread_yrange = obj.SignalYRange
                opt2.spread_psf_warn_threshold = obj.SpreadMatrix_EdgePSFVal_WarnThreshold
                opt2.spread_psf_radius = obj.SpreadMatrix_PSFRadius * ...
                        (obj.PointSource.RayleighResolution * obj.PointSource.InitResolutionRatio)
            end
            if isempty(counts)
                counts = zeros(size(sites, 1), 1);
                counts(ceil(size(sites, 1) / 2)) = 100;
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
            if isempty(opt1.transform_matrix)
                [M, x_range, y_range] = obj.getSpreadMatrix( ...
                    'spread_sites', sites, ...
                    'spread_center', obj.Lattice.R, args{:});
            else
                M = opt1.transform_matrix;
                x_range = opt2.spread_xrange;
                y_range = opt2.spread_yrange;
            end
            reconstructed = reshape(M' * counts, length(x_range), length(y_range));
        end
    end

    methods (Static)
        function plotHist(counts)
        end

        % Generate some statistical analysis on error and loss rates
        function description = describe(occup, options)
            arguments
                occup
                options.verbose = false
            end
            [num_sites, num_frames, num_acq] = size(occup, 1:3);
            total = reshape(sum(occup, 1), num_frames, num_acq);
            description.N = total;
            description.F = total / num_sites;
            description.MeanSub.N = mean(total, 1);
            description.MeanSub.F = description.MeanSub.N / num_sites;
            description.MeanAcq.N = mean(total, 2);
            description.MeanAcq.F = description.MeanAcq.N / num_sites;
            description.MeanAll.N = mean(total, 'all');
            description.MeanAll.F = description.MeanAll.N / num_sites;
            if num_frames ~= 1
                early = occup(:, 2:end, :);
                later = occup(:, 1:(end - 1), :);
                description.N1 = reshape(sum(early, 1), num_frames-1, num_acq);
                description.N2 = reshape(sum(later, 1), num_frames-1, num_acq);
                description.N11 = reshape(sum(early & later, 1), num_frames-1, num_acq);
                description.N10 = reshape(sum(early & ~later, 1), num_frames-1, num_acq);
                description.N01 = reshape(sum(~early & later, 1), num_frames-1, num_acq);
                description.N00 = reshape(sum(~early & ~later, 1), num_frames-1, num_acq);
                description.Loss = description.N1 - description.N2;
                description.MeanSub.LossRate = reshape(sum(description.Loss, 1) ./ sum(description.N1, 1), 1, []);
                description.MeanSub.ErrorRate = reshape(sum(description.N10, 1) ./ sum(description.N1, 1), 1, []);
                description.MeanAcq.LossRate = sum(description.Loss, 2) ./ sum(description.N1, 2);
                description.MeanAcq.ErrorRate = sum(description.N10, 2) ./ sum(description.N1, 2);
                description.MeanAll.LossRate = sum(description.Loss, 'all') ./ sum(description.N1, 'all');
                description.MeanAll.ErrorRate = sum(description.N10, 'all') ./ sum(description.N1, 'all');
            end
            if options.verbose
                disp(description.MeanAll)
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
    if isempty(obj.DeconvWeight)
        counts = [];
        obj.warn2('No deconvolution weights found, can not extract counts.')
        return
    end
    counts = obj.DeconvWeight * reshape(signal(x_range, y_range), [], 1);
end

%% Functions to extract occupancy from counts
function occup = getOccup_SingleThreshold(counts, thresholds)
    occup = counts > thresholds;
end

function [occup, prob, threshold, model] = getOccup_GMMThreshold(counts)
    model = fitgmdist(counts(:), 2);
    prob = model.posterior(counts(:));
    if model.mu(1) > model.mu(2)
        occup = prob(:, 1) > prob(:, 2);
        prob = prob(:, 1);
    else
        occup = prob(:, 2) > prob(:, 1);
        prob = prob(:, 2);
    end
    occup = reshape(occup, size(counts));
    prob = reshape(prob, size(counts));
    % Compute thresholds from 2-components Gaussian mixture model
    A = model.Sigma(1)^2 - model.Sigma(2)^2;
    B = -2*model.Sigma(1)^2 * model.mu(2) + 2*model.Sigma(2)^2 * model.mu(1);
    D = model.Sigma(1)^2 * model.mu(2)^2 - model.Sigma(2)^2 * model.mu(1)^2 ...
        - 2*model.Sigma(1)^2 * model.Sigma(2)^2 * log( ...
        model.ComponentProportion(2) * model.Sigma(1) / (model.ComponentProportion(1) * model.Sigma(2)));
    threshold1 = (-B + sqrt(B^2 - 4*A*D)) / (2*A);
    threshold2 = (-B - sqrt(B^2 - 4*A*D)) / (2*A);
    if (threshold1 < max(model.mu)) && (threshold1 > min(model.mu))
        threshold = threshold1;
    else
        threshold = threshold2;
    end
end

%% Utility functions
function plotCountsDiagnostic(obj, stat, signal, num_frames, index)
    signal = signal(:, :, index);
    lat = obj.Lattice;
    sites = stat.SiteInfo.Sites;
    counts = stat.LatCount(:, :, index);
    occup = stat.LatOccup(:, :, index);
    [x_size, y_size] = size(signal);
    centers = lat.R + (0: (num_frames - 1))' .* [(x_size / num_frames), 0];
    figure('Name', 'Diagnostic plots for counts reconstruction')
    subplot(1, 3, 1)
    imagesc2(signal)
    for j = 1: num_frames
        lat.plotOccup(sites(occup(:, j), :), sites(~occup(:, j), :), ...
            'center', centers(j, :), 'filter', true, ...
            'x_lim', [0, x_size], 'y_lim', [0, y_size])
    end
    lat.plotV('center', centers)
    title('Signal')
    subplot(1, 3, 2)
    simulated = zeros(x_size, y_size);
    for j = 1: num_frames
        x_range = (1: (x_size / num_frames)) + (j - 1) * (x_size / num_frames);
        simulated(x_range, 1: y_size) = obj.reconstructSignal(counts(:, j));
    end
    imagesc2(simulated)
    subplot(1, 3, 3)
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
