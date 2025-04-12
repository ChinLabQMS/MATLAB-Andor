 classdef Lattice < BaseComputer
    %LATTICE Class for lattice calibration and conversion

    properties (Constant)
        Standard_R = [0, 0]
        Standard_V1 = [0, 1]  % Unit length lattice vector for a "standard" image
        Standard_V2 = [-1/2*sqrt(3), -1/2]
        TransformStandard_StepDensity = 10
        TransformStandard_XLim = [-25, 25]
        TransformStandard_YLim = [-25, 25]
        CalibR_Binarize = true
        CalibR_BinarizeThresPerct = 0.5
        CalibR_MinBinarizeThres = 30
        CalibR_Bootstrapping = false
        CalibR_PlotDiagnostic = false
        CalibV_RFitFFT = 10
        CalibV_CalibR = true
        CalibV_WarnLatNormThres = 0.001
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibO_InverseMatch = false
        CalibO_ConvertToSignal = true
        CalibO_CalibR = true
        CalibO_CalibR_Bootstrap = false
        CalibO_Sites = SiteGrid.prepareSite('Hex', 'latr', 3)
        CalibO_DistanceMetric = "cosine"
        CalibO_NumScores = 5
        CalibO_WarnThresScoreDev = 5
        CalibO_Verbose = false
        CalibO_Debug = false
        CalibO_PlotDiagnostic = false
        CalibProjectorPattern_Shape = "HashLines"
        CalibProjectorVRHash_HashXLine = [667, 817]
        CalibProjectorVRHash_HashYLine = [666, 816]
        CalibProjectorVRHash_FFTAngKDE_BW = 1
        CalibProjectorVRHash_FFTAngKDE_Points = linspace(0, 180, 3600)
        CalibProjectorVRHash_FFTAng_PeakOrder = "ascend"
        CalibProjectorVRHash_FFTAng_PlotDiagnostic = false
        CalibProjectorVRHash_ProjKDE_BW = 1
        CalibProjectorVRHash_ProjKDE_NPoints = 10000
        CalibProjectorVRHash_ProjKDE_PeakOrder = ["ascend", "descend"]
        CalibProjectorVRHash_ProjKDE_PlotDiagnostic = false
        CalibProjectorVRHash_ProjectorSize = [1482, 1481]
        CalibProjectorVRHash_TemplatePath = "resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp"
        CalibProjectorVRHash_PlotDiagnostic = true
    end

    properties (SetAccess = immutable)
        PixelSize          % um
        RealSpacing        % um
    end

    properties (SetAccess = protected)
        K  % Momentum-space reciprocal vectors, 2x2 double
        V  % Real-space lattice vectors, 2x2 double
        R  % Real-space lattice center, 1x2 double
        Rstat  % Statistics generated during calibrating lattice R
        Ostat  % Statistics generated during cross calibrating lattice R
        ProjectorV % Camera space projector V vector
        ProjectorR % Camera space projector R vector
    end

    properties (Dependent, Hidden)
        V1
        V2
        V3
        V_norm
        Magnification
    end
    
    methods
        function obj = Lattice(id, pixel_size, spacing, options)
            arguments
                id = "Standard"
                pixel_size = 13
                spacing = 0.8815
                options.v1 = Lattice.Standard_V1
                options.v2 = Lattice.Standard_V2
                options.r = Lattice.Standard_R
                options.verbose = false
            end
            obj@BaseComputer(id)
            obj.PixelSize = pixel_size;
            obj.RealSpacing = spacing;
            if id == "Standard"
                obj.init(options.r, [], spacing*[options.v1; options.v2], ...
                    "format", "KV")
            end
            if options.verbose
                obj.info('Empty object created, pixel_size = %.3g um, physical lattice spacing = %.3g um.', pixel_size, spacing)
            end
        end
        
        % Initialize the calibration by
        % - setting the lattice center
        % - (or), specify a FFT peak position for getting K and V
        function init(obj, R, arg1, arg2, options)
            arguments
                obj
                R = []
                arg1 = []
                arg2 = []
                options.format = "peak_pos"
                options.verbose = false
            end
            if ~isempty(arg2) || ~isempty(arg1)
                switch options.format
                    case "peak_pos"
                        if ~isempty(arg2) && ~isempty(arg1)
                            [obj.K, obj.V] = convertFFTPeak2K(arg1, arg2);
                        else
                            obj.error("Wrong input format for peak_pos.")
                        end
                    case "KV"
                        if ~isempty(arg1)
                            obj.K = arg1;
                        else
                            obj.K = inv(arg2)';
                        end
                        if ~isempty(arg2)
                            obj.V = arg2;
                        else
                            obj.V = inv(arg1)';
                        end
                    case "obj"
                        obj.K = arg1.K;
                        obj.V = arg1.V;
                        obj.R = arg1.R;
                    case "R"
                    otherwise
                        obj.error('Unrecongized input format %s.', options.format)
                end
            end
            if ~isempty(R)
                old_R = obj.R;
                obj.R = R;
                if options.verbose
                    obj.info("Lattice center is set to (%g, %g), originally (%g, %g)", ...
                        R(1), R(2), old_R(1), old_R(2))
                end
            end
        end
        
        % Copy the values to a different lattice object
        function obj2 = copy(obj, options)
            arguments
                obj
                options.v = obj.V
                options.r = obj.R
            end
            obj.checkInitialized()
            obj2 = Lattice(obj.ID, obj.PixelSize, obj.RealSpacing);
            obj2.init(options.r, [], options.v, "format", "KV")
        end
        
        % Convert lattice space coordinates to real space
        % Accept center as N by 2 array
        function [coor, sites] = convert2Real(obj, sites, options)
            arguments
                obj
                sites = []
                options.center = obj.R
                options.filter = false
                options.x_lim = [1, Inf]
                options.y_lim = [1, Inf]
                options.full_range = false
                options.remove_origin = false
            end
            % If generate lattice sites for the full range
            if options.full_range
                corners = [options.x_lim(1), options.y_lim(1);
                           options.x_lim(2), options.y_lim(1);
                           options.x_lim(1), options.y_lim(2);
                           options.x_lim(2), options.y_lim(2)];
                lat_corners = (corners - obj.R)/obj.V;
                lat_xmin = ceil(min(lat_corners(:, 1)));
                lat_xmax = floor(max(lat_corners(:, 1)));
                lat_ymin = ceil(min(lat_corners(:, 2)));
                lat_ymax = floor(max(lat_corners(:, 2)));
                [Y, X] = meshgrid(lat_ymin:lat_ymax, lat_xmin:lat_xmax);
                sites = [X(:), Y(:)];
            end
            % If discard origin in the lattice coordinate
            if options.remove_origin
                idx = sites(:, 1) == 0 & sites(:, 2) == 0;
                sites = sites(~idx, :);
            end
            % Transform coordinates to real space
            options.center = permute(options.center, [3, 2, 1]);
            coor = sites * obj.V + options.center;            
            % Filter lattice sites outside of a rectangular limit area
            if options.filter
                idx = all(coor(:, 1, :) >= options.x_lim(1), 3) & ...
                      all(coor(:, 1, :) <= options.x_lim(2), 3) & ...
                      all(coor(:, 2, :) >= options.y_lim(1), 3) & ...
                      all(coor(:, 2, :) <= options.y_lim(2), 3);
                coor = coor(idx, :, :);
                sites = sites(idx, :, :);
            end
        end
        
        % Convert real-space coordinates to lattice space
        function sites = convert2Lat(obj, coor)
            sites = (coor - obj.R) * obj.K';
        end

        % Convert projector space coordinates to camera (obj) space
        function [coor, proj_coor] = convertProjector2Camera(obj, proj_coor, options)
            arguments
                obj
                proj_coor = []
                options.center = obj.ProjectorR
                options.filter = false
                options.x_lim = [1, Inf]
                options.y_lim = [1, Inf]
            end
            % Transform coordinates to camera space
            options.center = permute(options.center, [3, 2, 1]);
            coor = proj_coor * obj.ProjectorV + options.center;    
            % Filter sites outside of a rectangular limit area
            if options.filter
                idx = all(coor(:, 1, :) >= options.x_lim(1), 3) & ...
                      all(coor(:, 1, :) <= options.x_lim(2), 3) & ...
                      all(coor(:, 2, :) >= options.y_lim(1), 3) & ...
                      all(coor(:, 2, :) <= options.y_lim(2), 3);
                coor = coor(idx, :, :);
                proj_coor = proj_coor(idx, :, :);
            end
        end
        
        % Calibrate lattice center (R) by FFT phase
        function calibrateR(obj, signal, x_range, y_range, optionsR)
            arguments
                obj
                signal
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                optionsR.binarize = obj.CalibR_Binarize
                optionsR.binarize_thres_perct = obj.CalibR_BinarizeThresPerct
                optionsR.min_binarize_thres = obj.CalibR_MinBinarizeThres
                optionsR.bootstrapping = obj.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = obj.CalibR_PlotDiagnostic
            end
            % If the image is not directly from imaging lattice, do filtering
            if optionsR.binarize
                signal_new = filterSignal(signal, optionsR.binarize_thres_perct, optionsR.min_binarize_thres);
            else
                signal_new = signal;
            end
            signal = mean(signal, 3);
            signal_new = mean(signal_new, 3);
            % Update obj.R
            obj.R = obj.convertFFTPhase2R(signal_new, x_range, y_range);
            obj.Rstat = getSubStat(obj, signal_new, x_range, y_range, optionsR.bootstrapping);
            if optionsR.plot_diagnosticR
                figure('Name', 'Lattice R calibration diagnostics')
                subplot(1, 2, 1)
                imagesc2(y_range, x_range, signal, "title", sprintf("%s: Signal", obj.ID))
                obj.plot('filter', true, 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                obj.plotV()
                subplot(1, 2, 2)
                imagesc2(y_range, x_range, signal_new, "title", sprintf("%s: Signal (discrete)", obj.ID))
                obj.plot('filter', true, 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                obj.plotV()
            end
        end
        
        % Calibrate lattice center (R) by FFT phase with cropped signal
        function calibrateRCrop(obj, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, obj.R, crop_R);
            obj.calibrateR(signal, x_range, y_range, varargin{:})
        end

        % Calibrate lattice center (R) by FFT phase with cropped signal,
        % crop radius is in the unit of lattice spacing
        function calibrateRCropSite(obj, signal, crop_R_site, varargin)
            calibrateRCrop(obj, signal, crop_R_site * obj.V_norm, varargin{:})
        end
        
        % Calibrate lattice vectors with FFT, then lattice centers
        function calibrate(obj, signal, x_range, y_range, optionsV, optionsR)
            arguments
                obj
                signal
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                optionsV.R_fit = obj.CalibV_RFitFFT
                optionsV.calib_R = obj.CalibV_CalibR
                optionsV.warning_rsquared = obj.CalibV_WarnRSquared
                optionsV.warning_latnorm_thres = obj.CalibV_WarnLatNormThres                
                optionsV.plot_diagnosticV = obj.CalibV_PlotDiagnostic
                optionsR.binarize = obj.CalibR_Binarize
                optionsR.binarize_thres_perct = obj.CalibR_BinarizeThresPerct
                optionsR.min_binarize_thres = obj.CalibR_MinBinarizeThres
                optionsR.bootstrapping = obj.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = obj.CalibR_PlotDiagnostic
            end
            LatInit = obj.struct();
            % If the image is not directly from imaging lattice, do filtering
            if optionsR.binarize
                signal_new = filterSignal(signal, optionsR.binarize_thres_perct, optionsR.min_binarize_thres);
            else
                signal_new = signal;
            end
            signal_new = mean(signal_new, 3);
            signal_fft = abs(fftshift(fft2(signal_new)));
            xy_size = size(signal_new, [1, 2]);
            % Start from initial calibration, find FFT peaks
            peak_init = convertK2FFTPeak(xy_size, obj.K);
            [peak_pos, peak_info] = fitFFTPeaks(signal_fft, peak_init, optionsV.R_fit);
            for peak = peak_info
                if peak.GOF.rsquare < optionsV.warning_rsquared
                    obj.warn('FFT peak fit at (%5.2f, %5.2f) might be off (rsquare=%.3f).', ...
                        peak.PeakFit.x0, peak.PeakFit.y0, peak.GOF.rsquare)
                end
            end
            % Use fitted FFT peak position to get new calibration
            [obj.K, obj.V] = convertFFTPeak2K(xy_size, peak_pos);
            % Re-calibrate lattice centers to snap it into grid
            if optionsV.calib_R
                argsR = namedargs2cell(optionsR);
                obj.calibrateR(signal, x_range, y_range, argsR{:})
            end
            % Compute lattice vector norm changes
            VDis = vecnorm(obj.V'-LatInit.V')./vecnorm(LatInit.V');
            if any(VDis > optionsV.warning_latnorm_thres)
                obj.warn("Lattice vector length changed significantly by %.2f%%.",...
                         100*(max(VDis)))
            end
            if optionsV.plot_diagnosticV
                plotFFT(signal_fft, peak_init, peak_pos, peak_info, obj.ID)
            end
        end

        % Calibrate lattice vectors with FFT, then lattice centers with
        % cropped signal
        function calibrateCrop(obj, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, obj.R, crop_R);
            obj.calibrate(signal, x_range, y_range, varargin{:})
        end

        % Calibrate lattice vectors with FFT, then lattice centers with
        % cropped signal, crop radius is in the unit of lattice spacing
        function calibrateCropSite(obj, signal, crop_R_site, varargin)
            calibrateCrop(obj, signal, crop_R_site * obj.V_norm, varargin{:})
        end

        % Convert coordinates coor in obj space to Lat2 space
        function [coor2, sites] = transform(obj, Lat2, coor, options)
            arguments
                obj
                Lat2
                coor = []
                options.round_output = false
            end
            [coor2, sites] = Lat2.convert2Real(obj.convert2Lat(coor), 'filter', false);
            if options.round_output
                coor2 = round(coor2);
            end
        end

        % Cross conversion of one image from obj to Lat2
        % for all pixels within (x_range2, y_range2) in Lat2 space
        function transformed2 = transformSignal(obj, Lat2, x_range2, y_range2, ...
                signal, x_range, y_range)
            arguments
                obj
                Lat2
                x_range2
                y_range2
                signal
                x_range {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
            end
            % All pixels in Lat2 camera space
            [Y2, X2] = meshgrid(y_range2, x_range2);
            coor2 = [X2(:), Y2(:)];
            % Corresponding pixel position in obj camera space
            coor = Lat2.transform(obj, coor2, "round_output", true);
            % Look up the values at corresponding pixels
            idx = (coor(:, 1) >= x_range(1)) & (coor(:, 1) <= x_range(end)) ...
                & (coor(:, 2) >= y_range(1)) & (coor(:, 2) <= y_range(end));
            transformed2 = zeros(length(x_range2), length(y_range2));
            transformed2(idx) = signal(coor(idx, 1) - x_range(1) + 1 ...
                + (coor(idx, 2) - y_range(1)) * size(signal, 1));
        end
        
        % Cross conversion of one (functional, smooth) image (function handle)
        % from obj to Lat2 for all pixels within (x_range2, y_range2) in Lat2 space
        function transformed2 = transformFunctional( ...
                obj, Lat2, x_range2, y_range2, func)
            [Y2, X2] = meshgrid(y_range2, x_range2);
            coor = Lat2.transform(obj, [X2(:), Y2(:)], "round_output", false);
            val = func(coor(:, 1), coor(:, 2));
            idx = ~isnan(val);
            transformed2 = zeros(length(x_range2), length(y_range2));
            transformed2(idx) = val(idx);
        end
        
        % Cross conversion of one image from obj space to a standard Lat2
        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandard( ...
                obj, signal, x_range, y_range, options1, options2)
            arguments
                obj
                signal 
                x_range = 1: size(signal, 1)
                y_range = 1: size(signal, 2)
                options1.r = obj.Standard_R
                options1.v1 = obj.Standard_V1
                options1.v2 = obj.Standard_V2
                options2.scale = obj.TransformStandard_StepDensity
                options2.x_lim = obj.TransformStandard_XLim
                options2.y_lim = obj.TransformStandard_YLim
            end
            args = namedargs2cell(options1);
            Lat2 = Lattice('Standard', obj.PixelSize, obj.RealSpacing, args{:});
            x_range2 = options2.x_lim(1): 1/options2.scale: options2.x_lim(2);
            y_range2 = options2.y_lim(1): 1/options2.scale: options2.y_lim(2);
            transformed2 = obj.transformSignal(Lat2, x_range2, y_range2, signal, x_range, y_range);
            if ~isempty(obj.ProjectorV)
                Lat2.ProjectorV = obj.ProjectorV / obj.V * Lat2.V;
                Lat2.ProjectorR = (obj.ProjectorR - obj.R) / obj.V * Lat2.V;
            end
        end

        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCrop(obj, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, obj.R, crop_R);
            [transformed2, x_range2, y_range2, Lat2] = obj.transformSignalStandard(signal, x_range, y_range, varargin{:});
        end

        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCropSite(obj, signal, crop_R_site, varargin)
            [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCrop(obj, signal, crop_R_site * obj.V_norm, varargin{:});
        end

        function [transformed2, x_range2, y_range2, Lat2] = transformFunctionalStandard( ...
                obj, func, options1, options2)
            arguments
                obj
                func
                options1.r = obj.Standard_R
                options1.v1 = obj.Standard_V1
                options1.v2 = obj.Standard_V2
                options2.scale = obj.TransformStandard_StepDensity
                options2.x_lim = obj.TransformStandard_XLim
                options2.y_lim = obj.TransformStandard_YLim
            end
            args = namedargs2cell(options1);
            Lat2 = Lattice('Standard', obj.PixelSize, obj.RealSpacing, args{:});
            x_range2 = options2.x_lim(1): 1/options2.scale: options2.x_lim(2);
            y_range2 = options2.y_lim(1): 1/options2.scale: options2.y_lim(2);
            transformed2 = obj.transformFunctional(Lat2, x_range2, y_range2, func);
        end

        % Calibrate the origin of obj to Lat2 based on signal overlapping
        function calibrateO(obj, Lat2, signal, signal2, ...
                x_range, y_range, x_range2, y_range2, options)
            arguments
                obj
                Lat2
                signal
                signal2
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                x_range2 {mustBeValidRange(signal2, 1, x_range2)} = 1:size(signal2, 1)
                y_range2 {mustBeValidRange(signal2, 2, y_range2)} = 1:size(signal2, 2)
                options.covert_to_signal = obj.CalibO_ConvertToSignal
                options.inverse_match = obj.CalibO_InverseMatch
                options.calib_R = obj.CalibO_CalibR
                options.calib_R_bootstrap = obj.CalibO_CalibR_Bootstrap
                options.sites = obj.CalibO_Sites
                options.metric = obj.CalibO_DistanceMetric
                options.debug = obj.CalibO_Debug
                options.verbose = obj.CalibO_Verbose
                options.num_scores = obj.CalibO_NumScores
                options.warn_thres_score_dev = obj.CalibO_WarnThresScoreDev
                options.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            obj.checkInitialized()
            Lat2.checkInitialized()
            if options.calib_R(1)
                obj.calibrateR(signal, x_range, y_range, "bootstrapping", options.calib_R_bootstrap)
            end
            if options.calib_R(end)
                Lat2.calibrateR(signal2, x_range2, y_range2, "bootstrapping", options.calib_R_bootstrap)
            end
            R_init = obj.R;
            num_sites = size(options.sites, 1);
            score.Site = options.sites;
            score.Center = obj.convert2Real(options.sites, "filter", false);
            score.SignalDist = nan(num_sites, 1);
            best_score = inf;
            best_transformed = [];
            for i = 1: num_sites
                obj.R = score.Center(i, :);
                if options.covert_to_signal
                    transformed = Lat2.transformSignal(obj, x_range, y_range, signal2, x_range2, y_range2);
                    d = pdist2(signal(:)', transformed(:)', options.metric);
                else
                    transformed = obj.transformSignal(Lat2, x_range2, y_range2, signal, x_range, y_range);
                    d = pdist2(signal2(:)', transformed(:)', options.metric);
                end
                if options.inverse_match
                    score.SignalDist(i) = -d;
                else
                    score.SignalDist(i) = d;
                end
                if score.SignalDist(i) < best_score
                    best_score = score.SignalDist(i);
                    best_transformed = transformed;
                end
            end
            score = struct2table(score);
            options.num_scores = min(options.num_scores, num_sites);
            [min_val, min_idx] = mink(score.SignalDist, options.num_scores);
            best = score(min_idx(1), :);
            others = score(min_idx(2:end), :);
            obj.R = best.Center;
            obj.Ostat = table2struct(best);
            obj.Ostat.Others = others;
            obj.Ostat.BestTransformed = best_transformed;
            obj.Ostat.OriginalSignal = signal;
            info_str = sprintf("Center is calibrated to %s, now at (%.1f, %.1f) = (%5.2f, %5.2f) px, initially at (%5.2f, %5.2f) px, min dist = %5.3f among (%s).", ...
                    Lat2.ID, best.Site(1), best.Site(2), best.Center(1), best.Center(2), ...
                    R_init(1), R_init(2), best.SignalDist, join(string(compose('%4.3f', min_val)), ", "));
            if all(best.Site == [0, 0]) && ...
                    abs(best.SignalDist - mean(others.SignalDist))/std(others.SignalDist) > options.warn_thres_score_dev
                if options.verbose
                    obj.info("%s", info_str)
                end
            else
                obj.warn("%s", info_str)
            end
            if options.plot_diagnosticO
                plotSimilarityMap(x_range, y_range, score, best)
                obj.plotV()
                if ~options.debug
                    plotTransformation(obj, Lat2, R_init, signal, signal2, best_transformed, ...
                        x_range, y_range, x_range2, y_range2, options.covert_to_signal)
                end
            end
            if options.debug  % Reset to initial R
                obj.R = R_init;
            end
        end

        % Calibrate the origin of obj to Lat2 based on signal overlapping,
        % with cropped signal, crop radius is in the unit of lattice
        % spacing
        function calibrateOCropSite(obj, Lat2, signal, signal2, ...
                crop_R_site, varargin)
            [signal, x_range, y_range] = prepareBox(signal, obj.R, crop_R_site * obj.V_norm);
            [signal2, x_range2, y_range2] = prepareBox(signal2, Lat2.R, crop_R_site * Lat2.V_norm);
            obj.calibrateO(Lat2, signal, signal2, x_range, y_range, x_range2, y_range2, varargin{:})
        end

        % Assume current obj is in projector space, calibrate the lattice
        % with a given camera space lattice
        % Update the lattice coordinates calibration (R, V) to
        % projector-camera calibration for a given camera lattice
        % Assume the current obj is at projector space
        function calibrateProjector2Camera(obj, Lat)
            if isempty(Lat.ProjectorV)
                obj.error('Camera space Projector V R is not calibrated!')
            end
            obj.V = Lat.V / Lat.ProjectorV;
            obj.K = inv(obj.V)';
            obj.R = (Lat.R - Lat.ProjectorR) / Lat.ProjectorV;
        end

        % Assume current obj is in camera space, calibrate the projector
        % space VR (ProjectorV, ProjectorR) with hash pattern
        function calibrateProjectorVRHash(obj, signal, x_range, y_range, opt1, opt2, opt3)
            arguments
                obj
                signal
                x_range = 1: size(signal, 1)
                y_range = 1: size(signal, 2)
                opt1.hash_xline = obj.CalibProjectorVRHash_HashXLine
                opt1.hash_yline = obj.CalibProjectorVRHash_HashYLine
                opt1.x_lim = [x_range(1), x_range(end)]
                opt1.y_lim = [y_range(1), y_range(end)]
                opt1.projector_size = obj.CalibProjectorVRHash_ProjectorSize
                opt2.fftang_kde_bw = obj.CalibProjectorVRHash_FFTAngKDE_BW
                opt2.fftang_kde_points = obj.CalibProjectorVRHash_FFTAngKDE_Points
                opt2.fftang_peak_order = obj.CalibProjectorVRHash_FFTAng_PeakOrder
                opt2.fftang_plot_diagnostic = obj.CalibProjectorVRHash_FFTAng_PlotDiagnostic
                opt2.proj_kde_bw = obj.CalibProjectorVRHash_ProjKDE_BW
                opt2.proj_kde_npoints = obj.CalibProjectorVRHash_ProjKDE_NPoints
                opt2.proj_kde_peak_order = obj.CalibProjectorVRHash_ProjKDE_PeakOrder
                opt2.proj_plot_diagnostic = obj.CalibProjectorVRHash_ProjKDE_PlotDiagnostic
                opt3.template_path = obj.CalibProjectorVRHash_TemplatePath
                opt3.plot_diagnostic = obj.CalibProjectorVRHash_PlotDiagnostic
            end
            fft_ang = findFFTAngle(signal, opt2.fftang_kde_bw, ...
                opt2.fftang_kde_points, opt2.fftang_peak_order, ...
                opt2.fftang_plot_diagnostic);
            [peak_pos, norm_K] = findProjDensityPeak(fft_ang, 2, signal, x_range, y_range, ...
                opt2.proj_kde_bw, opt2.proj_kde_npoints, opt2.proj_kde_peak_order, ...
                opt2.proj_plot_diagnostic);
            [obj.ProjectorV, obj.ProjectorR] = mapLineFeatures( ...
                opt1.hash_xline, opt1.hash_yline, peak_pos, norm_K);
            if opt3.plot_diagnostic
                args = namedargs2cell(opt1);
                figure('Name', 'Camera image and transformed projector pattern (Hash lines)')
                ax1 = subplot(1, 2, 1);
                template = imread(opt3.template_path);
                imagesc(ax1, template)
                axis("image")
                title("Projector space")
                obj.plotHash(ax1, false, args{:})
                ax2 = subplot(1, 2, 2);
                imagesc(ax2, y_range, x_range, signal)
                axis(ax2, "image")
                title(ax2, 'Camera signal')
                obj.plotHash(ax2, true, args{:})
            end
        end

        % Overlaying the lattice sites, first two arguments (optional) are
        % axis handle and sites, then name-value pairs
        function varargout = plot(obj, varargin, opt1, opt2)
            arguments
                obj
            end
            arguments (Repeating)
                varargin  % Optional, site index/ax handle
            end
            arguments
                opt1.center = obj.R
                opt1.filter = false
                opt1.x_lim = []
                opt1.y_lim = []
                opt1.full_range = false
                opt2.color = "r"
                opt2.norm_radius = 0.1
                opt2.diff_origin = true
                opt2.origin_radius = 0.5
                opt2.line_width = 0.5
            end
            if isempty(varargin)
                ax = gca();
                sites = SiteGrid.prepareSite('Hex', 'latr', 20);
            elseif isscalar(varargin)
                ax = gca();
                sites = varargin{1};
            elseif length(varargin) == 2
                ax = varargin{1};
                sites = varargin{2};
            else
                obj.error("Unsupported number of input positional arguments.")
            end
            obj.checkInitialized()
            opt1.remove_origin = opt2.diff_origin;
            if (isempty(opt1.x_lim) || isempty(opt1.y_lim)) && opt1.filter
                opt1.x_lim = xlim(ax);
                opt1.y_lim = ylim(ax);
            end
            args = namedargs2cell(opt1);
            coor = reshape(permute(obj.convert2Real(sites, args{:}), [3, 1, 2]), [], 2);
            % Use a different radius to display origin
            if opt2.diff_origin
                radius = [repmat(opt2.norm_radius * obj.V_norm, size(coor, 1), 1);
                          repmat(opt2.origin_radius * obj.V_norm, size(opt1.center, 1), 1)];
                coor = [coor; opt1.center];
            else
                radius = opt2.norm_radius * obj.V_norm;
            end
            h = viscircles2(ax, coor(:, 2:-1:1), radius, ...
                'Color', opt2.color, 'EnhanceVisibility', false, ...
                'LineWidth', opt2.line_width);
            % Output the handle to the group of circles
            if nargout == 1
                varargout{1} = h;
            end
        end

        function varargout = plotOccup(obj, varargin, opt1, opt2)
            arguments
                obj
            end
            arguments (Repeating)
                varargin 
            end
            arguments
                opt1.center = obj.R
                opt1.filter = false
                opt1.x_lim = [1, 1440]
                opt1.y_lim = [1, 1440]
                opt2.plot_unoccup = true
                opt2.occup_color = 'r'
                opt2.unoccup_color = 'w'
                opt2.radius = 0.1
            end
            if isempty(varargin)
                ax = gca();
                occup = SiteGrid.prepareSite('Hex', 'latr', 20);
                unoccup = zeros(0, 2);
            elseif length(varargin) == 2
                ax = gca();
                occup = varargin{1};
                unoccup = varargin{2};
            elseif length(varargin) == 3
                ax = varargin{1};
                occup = varargin{2};
                unoccup = varargin{3};
            else
                obj.error("Unsupported number of input positional arguments.")
            end
            if ~opt2.plot_unoccup
                unoccup = zeros(0, 2);
            end
            args = namedargs2cell(opt1);
            h_occup = obj.plot(ax, occup, args{:}, 'diff_origin', false, ...
                    'norm_radius', opt2.radius, 'color', opt2.occup_color);
            h_unoccup = obj.plot(ax, unoccup, args{:}, 'diff_origin', false, ...
                    'norm_radius', opt2.radius, 'color', opt2.unoccup_color);
            if nargout == 1
                varargout{1} = [h_occup, h_unoccup];
            end
        end
        
        % Plot a count distribution
        function plotCounts(obj, varargin, opt1, opt2)
            arguments
                obj
            end
            arguments (Repeating)
                varargin
            end
            arguments
                opt1.center = obj.R
                opt1.filter = false
                opt1.x_lim = [1, 1440]
                opt1.y_lim = [1, 1440]
                opt1.full_range = false
                opt2.fill_sites = true
                opt2.fill_radius = 0.45
                opt2.scatter_radius = 50
                opt2.add_background = true
            end
            if isempty(varargin)
                ax = gca();
                sites = SiteGrid.prepareSite('Hex', 'latr', 20);
                counts = zeros(height(sites), 1);
            elseif length(varargin) == 2
                ax = gca();
                sites = varargin{1};
                counts = varargin{2};
            elseif length(varargin) == 3
                ax = varargin{1};
                sites = varargin{2};
                counts = varargin{3};
            else
                obj.error("Unsupported number of input positional arguments.")
            end
            obj.checkInitialized()
            c_obj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            args = namedargs2cell(opt1);
            coor = reshape(permute(obj.convert2Real(sites, args{:}), [3, 1, 2]), [], 2);
            counts = reshape(counts, [], 1);
            radius = opt2.fill_radius * obj.V_norm;
            if opt2.add_background
                bg = zeros(opt1.x_lim(2) - opt1.x_lim(1), opt1.y_lim(2) - opt1.y_lim(1));
                imagesc2(ax, opt1.y_lim(1):opt1.y_lim(2), opt1.x_lim(1):opt1.x_lim(2), bg);
            end
            if opt2.fill_sites
                viscircles2(ax, coor(:, 2:-1:1), radius, ...
                    'Color', 'r', 'EnhanceVisibility', false, ...
                    'LineWidth', 0, 'Filled', true, 'FillColor', counts);
            end
            hold(ax, "on")
            scatter(ax, coor(:, 2), coor(:, 1), opt2.scatter_radius, counts, "filled");
        end
        
        % Plot lattice vectors
        function varargout = plotV(obj, ax, options)
            arguments
                obj
                ax = gca()
                options.vector = obj.V
                options.center = obj.R
                options.scale = 1
                options.add_legend = true
            end
            obj.checkInitialized()
            c_obj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            hold(ax,'on');
            h(1) = quiver(ax, options.center(:, 2), options.center(:, 1), ...
                repmat(options.scale * options.vector(1, 2), size(options.center, 1), 1), ...
                repmat(options.scale * options.vector(1, 1), size(options.center, 1), 1), ...
                'off', 'LineWidth', 2, 'DisplayName', sprintf("%s: V1", obj.ID), ...
                'MaxHeadSize', 10, 'Color', 'r');
            h(2) = quiver(ax, options.center(:, 2), options.center(:, 1), ...
                repmat(options.scale * options.vector(2, 2), size(options.center, 1), 1), ...
                repmat(options.scale * options.vector(2, 1), size(options.center, 1), 1), ...
                'off', 'LineWidth', 2, 'DisplayName', sprintf("%s: V2", obj.ID), ...
                'MaxHeadSize', 10, 'Color', 'm');
            if options.add_legend
                legend(ax, 'Interpreter', 'none')
            end
            if nargout == 1
                varargout{1} = h;
            end
        end

        function plotHash(obj, ax, plot_transformed, options)
            arguments
                obj
                ax = gca()
                plot_transformed = true
                options.x_lim = [0, inf]
                options.y_lim = [0, inf]
                options.hash_xline = obj.CalibProjectorVRHash_HashXLine
                options.hash_yline = obj.CalibProjectorVRHash_HashYLine
                options.projector_size = obj.CalibProjectorVRHash_ProjectorSize
            end
            c_obj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            hold(ax,'on');
            num_xlines = length(options.hash_xline);
            num_ylines = length(options.hash_yline);
            for i = 1: num_xlines
                coor = [repmat(options.hash_xline(i), ...
                    options.projector_size(2), 1), (1: options.projector_size(2))'];
                if isempty(obj.ProjectorV) || ~plot_transformed
                    plot(ax, coor(:, 2), coor(:, 1), 'LineWidth', 2, ...
                         'DisplayName', "xline: " + string(i))
                else
                    transformed = obj.convertProjector2Camera(coor, 'filter', true, ...
                        'x_lim', options.x_lim, 'y_lim', options.y_lim);
                    plot(ax, transformed(:, 2), transformed(:, 1), ...
                    'LineStyle','--', 'LineWidth',2, 'DisplayName', "xline: " + string(i))
                end
            end
            for i = 1: num_ylines
                coor = [(1: options.projector_size(1))', ...
                    repmat(options.hash_yline(i), options.projector_size(1), 1), ];
                if isempty(obj.ProjectorV) || ~plot_transformed
                   plot(ax, coor(:, 2), coor(:, 1), 'LineWidth', 2, ...
                         'DisplayName', "yline: " + string(i))
                else
                    transformed = obj.convertProjector2Camera(coor, 'filter', true, ...
                        'x_lim', options.x_lim, 'y_lim', options.y_lim);
                    plot(ax, transformed(:, 2), transformed(:, 1), ...
                        'LineStyle','--', 'LineWidth',2, 'DisplayName', "yline: " + string(i))
                end
            end
        end
        
        % Convert the current K vector to an expected FFT peak location
        function peak_pos = convert2FFTPeak(obj, xy_size)
            obj.checkInitialized()
            peak_pos = convertK2FFTPeak(xy_size, obj.K);
        end
        
        % Convert FFT phase to lattice center R
        function R = convertFFTPhase2R(obj, signal, x_range, y_range)
            obj.checkInitialized()
            % Extract lattice center coordinates from phase at FFT peak
            [Y, X] = meshgrid(y_range, x_range);
            phase_vec = zeros(1,2);
            for i = 1:2
                phase_mask = exp(-1i*2*pi*(obj.K(i,1)*X + obj.K(i,2)*Y));
                phase_vec(i) = angle(sum(phase_mask.*signal, 'all'));
            end
            R = (round(obj.R*obj.K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * obj.V;
        end

        % Display lattice calibration details
        function disp(obj)
            fprintf('%s: \n', obj.getStatusLabel())
            if ~isempty(obj.K)
                s = obj.struct(["ID", "PixelSize", "RealSpacing", "Magnification"]);
                disp(s)
            else
                s = obj.struct(["ID", "PixelSize", "RealSpacing"]);
                disp(s)
                fprintf('Lattice calibration is not initialized.\n\n')
                return
            end
            v1 = obj.V1;
            v2 = obj.V2;
            v3 = obj.V3;            
            fprintf('Calibration result:\n')
            fprintf('\tR  = (%7.2f, %7.2f) px\n', obj.R(1), obj.R(2))
            fprintf('\tV1 = (%7.2f, %7.2f) px,\t|V1| = %7.2f px\n', v1(1), v1(2), norm(v1))
            fprintf('\tV2 = (%7.2f, %7.2f) px,\t|V2| = %7.2f px\n', v2(1), v2(2), norm(v2))
            fprintf('\tV3 = (%7.2f, %7.2f) px,\t|V3| = %7.2f px\n', v3(1), v3(2), norm(v3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(v1*v2'/(norm(v1)*norm(v2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n\n', acosd(v1*v3'/(norm(v1)*norm(v3))))
        end

        function val = get.V1(obj)
            obj.checkInitialized()
            val = obj.V(1, :);
        end

        function val = get.V2(obj)
            obj.checkInitialized()
            val = obj.V(2, :);
        end

        function val = get.V3(obj)
            val = obj.V1 + obj.V2;
        end

        function val = get.V_norm(obj)
            obj.checkInitialized()
            val = mean([norm(obj.V(1, :)), norm(obj.V(2, :))]);
        end

        function val = get.Magnification(obj)
            val = (obj.V_norm * obj.PixelSize) / obj.RealSpacing;
        end

        function s = struct(obj, fields)
            arguments
                obj
                fields = ["K", "V", "R", "ID", "PixelSize", "RealSpacing"]
            end
            s = struct@BaseObject(obj, fields);
        end
    end
    
    methods (Access = protected, Hidden)
        function checkInitialized(obj)
            if isempty(obj.K)
                obj.error("Lattice details are not initialized.")
            end
        end
    end

    methods (Static)
        function obj = struct2obj(s, ID, options)
            arguments
                s (1, 1) struct
                ID (1, 1) string = s.ID
                options.verbose (1, 1) logical = true
            end
            obj = Lattice(ID);
            obj.init(s.R, s.K, s.V, 'format', "KV")
            if options.verbose
                obj.info("Object loaded from structure.")
            end
        end

        function checkDiff(obj, Lat2, label, label2)
            arguments
                obj
                Lat2
                label = "old"
                label2 = "new"
            end
            V = [obj.V; obj.V(1, :) + obj.V(2, :)];
            V2 = [Lat2.V; Lat2.V(1, :) + Lat2.V(2, :)];
            fprintf('Difference between %s (%s) and %s (%s):\n', obj.ID, label, Lat2.ID, label2)
            fprintf('\t\t R = (%7.2f, %7.2f),\t R'' = (%7.2f, %7.2f),\tDiff = (%7.2f, %7.2f)\n', ...
                    obj.R(1), obj.R(2), Lat2.R(1), Lat2.R(2), Lat2.R(1) - obj.R(1), Lat2.R(2) - obj.R(2))
            for i = 1:3
                cos_theta = max(min(dot(V(i, :),V2(i, :))/(norm(V2(i, :))*norm(V(i, :))), 1), -1);
                theta_deg = real(acosd(cos_theta));
                fprintf('(V%d)\t V = (%7.2f, %7.2f),\t V'' = (%7.2f, %7.2f),\tAngle<V, V''> = %7.2f deg\n', ...
                    i, V(i, 1), V(i, 2), V2(i, 1), V2(i, 2), theta_deg)
            end
            for i = 1:3
                norm1 = norm(V(i, :));
                norm2 = norm(V2(i, :));
                fprintf('(V%d)\t|V| = %14.2f px,\t|V''| = %14.2f px,\tDiff = %9.2f px (%5.3f%%)\n', ...
                    i, norm1, norm2, norm2 - norm1, 100*(norm2 - norm1)/norm1)
            end
            fprintf('\n')
        end
    end
    
 end

% Convert FFT peak positions to K and V vectors
function [K, V] = convertFFTPeak2K(xy_size, peak_pos)
    % Position of DC components in a fftshift-ed 2D fft pattern
    xy_center = floor(xy_size / 2) + 1;
    % Convert peak positions to K vectors
    K = (peak_pos - xy_center)./xy_size;
    % Get real-space V vectors from K vectors
    V = (inv(K(1:2,:)))';
end

% Convert K vector to FFT peak positions
function peak_pos = convertK2FFTPeak(xy_size, K)
    xy_center = floor(xy_size / 2) + 1;
    peak_pos = K.*xy_size + xy_center;
end

% Use kde to find two line features in FFT angular spectrum and extract the
% angles
function peak_ang = findFFTAngle(signal, bw, eval_points, peak_order, plot_diagnostic)
    signal_fft = abs(fftshift(fft2(signal)));
    xy_size = size(signal_fft);
    xy_center = floor(xy_size / 2) + 1;
    [Y, X] = meshgrid(1: xy_size(2), 1: xy_size(1));
    K = ([X(:), Y(:)] - xy_center) ./ xy_size;
    ang = atan2d(K(:, 2), K(:, 1));
    [f, xf] = kde(ang, "Weight", signal_fft(:), "Bandwidth", bw, "EvaluationPoints", eval_points);
    peak_ang = findPeaks1D(xf, f, 2);
    peak_ang = sort(peak_ang, peak_order);
    if plot_diagnostic
        figure('Name', 'FFT angular spectrum (log)', 'OuterPosition',[100, 100, 1600, 600])
        ax1 = subplot(1, 3, 1);
        imagesc2(ax1, signal_fft)
        title(ax1, 'Signal FFT')
        ax2 = subplot(1, 3, 2);
        imagesc2(ax2, log(signal_fft))
        title(ax2, 'Signal FFT (log)')
        for ax = [ax1, ax2]
            hold(ax, "on")
            quiver(ax, xy_center(2), xy_center(1), ...
                sind(peak_ang(1)) * xy_size(2), cosd(peak_ang(1)) * xy_size(1), ...
                0.1, 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'K1', ...
                'MaxHeadSize', 0.5)
            quiver(ax, xy_center(2), xy_center(1), ...
                sind(peak_ang(2)) * xy_size(2), cosd(peak_ang(2)) * xy_size(1), ...
                0.1, 'LineWidth', 2, 'Color', 'm', 'DisplayName', 'K2', ...
                'MaxHeadSize', 0.5)
            legend()
        end
        subplot(1, 3, 3)
        plot(xf, f, 'DisplayName', 'signal density')
        hold on
        scatter(ang, signal_fft(:) / sum(signal_fft, 'all'), 2, 'DisplayName', 'signal')
        xline(peak_ang, '--', 'DisplayName', 'peak angle')
        legend()
        title('Angular spectrum')
    end
end

function [proj_density, K] = getProjectionDensity(proj_ang, signal, x_range, y_range, bw, num_points)
    num_ang = length(proj_ang);
    K = [cosd(proj_ang)', sind(proj_ang)'];
    [Y, X] = meshgrid(y_range, x_range);
    Kproj = [X(:), Y(:)] * K';
    proj_density = cell(num_ang, 2);
    for i = 1: num_ang
        [f, xf] = kde(Kproj(:, i), "Weight", signal(:), "Bandwidth", bw, "NumPoints", num_points);
        proj_density{i, 1} = xf;
        proj_density{i, 2} = f;
    end
end

function [peak_pos, K, proj_density] = findProjDensityPeak(fft_ang, num_lines, ...
    signal, x_range, y_range, bw, num_points, peak_order, plot_diagnostic)
    [proj_density, K] = getProjectionDensity(fft_ang, signal, x_range, y_range, bw, num_points);
    peak_pos{1} = findPeaks1D(proj_density{1, 1}, proj_density{1, 2}, num_lines(1));
    peak_pos{2} = findPeaks1D(proj_density{2, 1}, proj_density{2, 2}, num_lines(end));
    peak_pos{1} = sort(peak_pos{1}, peak_order(1));
    peak_pos{2} = sort(peak_pos{2}, peak_order(2));
    if plot_diagnostic
        figure('Name', 'Image projection density', 'OuterPosition',[100, 100, 1600, 600])
        ax = subplot(1, 3, 1);
        imagesc2(ax, y_range, x_range, signal);
        hold(ax, "on")
        quiver(ax, (y_range(1) + y_range(end))/2, (x_range(1) + x_range(end))/2, ...
            K(1, 2), K(1, 1), 400, 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'K1', ...
            'MaxHeadSize', 10)
        quiver(ax, (y_range(1) + y_range(end))/2, (x_range(1) + x_range(end))/2, ...
            K(2, 2), K(2, 1), 400, 'LineWidth', 2, 'Color', 'm', 'DisplayName', 'K2', ...
            'MaxHeadSize', 10)
        legend(ax)
        for i = 1: 2
            subplot(1, 3, i + 1)
            plot(proj_density{i, 1}, proj_density{i, 2})
            hold on
            xline(peak_pos{i}, '--')
            title(sprintf('K%d projection', i))
        end
    end
end

function [V, R] = mapLineFeatures(x, y, peak_pos, K)
    p = peak_pos{2};
    q = peak_pos{1};
    p_mean = mean(p);
    q_mean = mean(q);
    x_mean = mean(x);
    y_mean = mean(y);
    V = [0, (x - x_mean) * (p - p_mean)' / ((x - x_mean) * (x - x_mean)');
         (y - y_mean) * (q - q_mean)' / ((y - y_mean) * (y - y_mean)'), 0] / K';
    R = [q_mean, p_mean] / K' - [x_mean, y_mean] * V;
end

% Use 2D Gauss fit to fit the FFT amplitude peaks
function [peak_pos, peak_info] = fitFFTPeaks(FFT, peak_init, R_fit)
    peak_pos = peak_init;
    num_peaks = size(peak_init, 1);
    peak_info(num_peaks) = struct();
    rx = R_fit(1);
    ry = R_fit(end);
    for i = 1:num_peaks
        center = round(peak_init(i, :));
        [peak_data, peak_x, peak_y] = prepareBox(FFT, center, [rx, ry]);        
        % Fitting FFT peaks
        [PeakFit, GOF, X, Y, Z] = fitGauss2D(peak_data, peak_x, peak_y, ...
            "offset", "linear", "cross_term", false);
        peak_info(i).PeakFit = PeakFit;
        peak_info(i).Data = {[X, Y], Z};
        peak_info(i).GOF = GOF;
        peak_pos(i, :) = [PeakFit.x0, PeakFit.y0];
    end
end

function [peak_x, peak_y, peak_idx] = findPeaks1D(x, y, num_peaks)
    peak_x = [];
    peak_y = [];
    peak_idx = [];
    for i = 2: length(x) - 1
        if y(i) > y(i - 1) && y(i) > y(i + 1)
            peak_x(end + 1) = x(i); %#ok<AGROW>
            peak_y(end + 1) = y(i); %#ok<AGROW>
            peak_idx(end + 1) = i; %#ok<AGROW>
        end
    end
    [~, sort_idx] = sort(peak_y, 'descend');
    sort_idx = sort_idx(1: num_peaks);
    peak_x = peak_x(sort_idx);
    peak_y = peak_y(sort_idx);
    peak_idx = peak_idx(sort_idx);
end

% Filter the signal with a given threshold percentage and min threshold
function signal_modified = filterSignal(signal, binarize_thres, min_binarize_thres)
    signal_modified = signal;
    thres = max(binarize_thres * max(signal(:)), min_binarize_thres);
    signal_modified(signal_modified < thres) = 0;
end

% Partition signal into 4 equal size subareas
function s = partitionSignal4(signal, x_range, y_range)
    arguments
        signal (:, :) double
        x_range (1, :) double = 1:size(signal, 1)
        y_range (1, :) double = 1:size(signal, 2)
    end
    x_idx1 = 1:floor(length(x_range) / 2);
    x_idx2 = floor(length(x_range) / 2) + 1: length(x_range);
    y_idx1 = 1:floor(length(y_range) / 2);
    y_idx2 = floor(length(y_range) / 2) + 1: length(y_range);
    x_idx = {x_idx1; x_idx1; x_idx2; x_idx2};
    y_idx = {y_idx1; y_idx2; y_idx1; y_idx2};
    s(4) = struct();
    for i = 1:4
        s(i).XRange = x_range(x_idx{i});
        s(i).YRange = y_range(y_idx{i});
        s(i).Signal = signal(x_idx{i}, y_idx{i});
    end
end

% Get statistics of the offset calibration of sub-areas
function res = getSubStat(obj, signal, x_range, y_range, if_bootstrap)
    res.R1 = obj.R(1);
    res.R2 = obj.R(2);
    LatR = obj.R / obj.V;
    res.LatR1 = LatR(1);
    res.LatR2 = LatR(2);
    if ~if_bootstrap
        return
    end
    s = partitionSignal4(signal, x_range, y_range);
    R_Sub = nan(length(s), 2);
    for i = 1:length(s)
        R_Sub(i, :) = obj.convertFFTPhase2R(s(i).Signal, s(i).XRange, s(i).YRange);
    end
    res.R1_Sub = R_Sub(:, 1)';
    res.R1_Mean = mean(R_Sub(:, 1));
    res.R1_Max = max(R_Sub(:, 1));
    res.R1_Min = min(R_Sub(:, 1));
    res.R1_Std = std(R_Sub(:, 1));
    res.R2_Sub = R_Sub(:, 2)';
    res.R2_Mean = mean(R_Sub(:, 2));
    res.R2_Max = max(R_Sub(:, 2));
    res.R2_Min = min(R_Sub(:, 2));
    res.R2_Std = std(R_Sub(:, 2));
    LatR_Sub = R_Sub / obj.V;
    res.LatR1_Sub = LatR_Sub(:, 1)';
    res.LatR1_Mean = mean(LatR_Sub(:, 1));
    res.LatR1_Max = max(LatR_Sub(:, 1));
    res.LatR1_Min = min(LatR_Sub(:, 1));
    res.LatR1_Std = std(LatR_Sub(:, 1));
    res.LatR2_Sub = LatR_Sub(:, 2)';
    res.LatR2_Mean = mean(LatR_Sub(:, 2));
    res.LatR2_Max = max(LatR_Sub(:, 2));
    res.LatR2_Min = min(LatR_Sub(:, 2));
    res.LatR2_Std = std(LatR_Sub(:, 2));
end

% Generate diagnostic plots on the FFT peak fits
function plotFFT(signal_fft, peak_init, peak_pos, peak_info, ID)
    num_peaks = size(peak_pos, 1);
    % Plot FFT magnitude in log scale
    figure("Name", "FFT peak fits diagnostics")
    sgtitle(ID, 'interpreter', 'none')
    subplot(1, num_peaks + 1, 1)
    imagesc2(log(signal_fft), "title", "log(FFT)")
    viscircles(peak_init(:, 2:-1:1), 7, "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
    viscircles(peak_pos(:, 2:-1:1), 2, "EnhanceVisibility", false, "Color", "red", "LineWidth", 1);
    hold on
    for i = 1: num_peaks
        x = peak_pos(i, 2);
        y = peak_pos(i, 1);
        text(x + 10, y, num2str(i), "FontSize", 16, 'Color', 'r')
    end
    % Plot FFT peaks fits
    for i = 1:num_peaks
        subplot(1, num_peaks + 1, i + 1)
        peak = peak_info(i);
        plot(peak.PeakFit, peak.Data{:})
        title(sprintf("Peak %d", i))
    end
end

function plotSimilarityMap(x_range, y_range, score, best)
    empty_image = zeros(length(x_range), length(y_range));
    score.Similarity = max(score.SignalDist) - score.SignalDist;
    figure('Name', 'Cross-calibration: Similarity map with scanning lattice origin')
    imagesc2(y_range, x_range, empty_image, "title", 'Similarity between images from different cameras')
    hold on
    scatter(best.Center(2), best.Center(1), 100, "red")
    scatter(score.Center(:, 2), score.Center(:, 1), 50, score.Similarity, 'filled')
end

function plotTransformation(obj, Lat2, R_init, signal, signal2, best_transformed, ...
                x_range, y_range, x_range2, y_range2, convert_to_signal)
    figure('Name', 'Cross-calibrated transformed images')
    if convert_to_signal
        subplot(1, 2, 1)
        imagesc2(y_range, x_range, signal, "title", sprintf("%s: reference", obj.ID))
        obj.plot()
        obj.plotV()
        viscircles(R_init(2:-1:1), 0.5*obj.V_norm, 'Color', 'w', ...
            'EnhanceVisibility', false, 'LineWidth', 0.5);
        subplot(1, 2, 2)
        imagesc2(y_range, x_range, best_transformed, "title", sprintf("%s: best transformed from %s", obj.ID, Lat2.ID))
        obj.plot()
        obj.plotV()
        viscircles(R_init(2:-1:1), 0.5*obj.V_norm, 'Color', 'w', ...
            'EnhanceVisibility', false, 'LineWidth', 0.5);
    else
        R_init = obj.transform(Lat2, R_init);
        subplot(1, 2, 1)
        imagesc2(y_range2, x_range2, signal2, "title", sprintf("%s: reference", Lat2.ID))
        Lat2.plot()
        Lat2.plotV()
        viscircles(R_init(2:-1:1), 0.5*Lat2.V_norm, 'Color', 'w', ...
            'EnhanceVisibility', false, 'LineWidth', 0.5);
        subplot(1, 2, 2)
        imagesc2(y_range2, x_range2, best_transformed, "title", sprintf("%s: best transformed from %s", Lat2.ID, obj.ID))
        Lat2.plot()
        Lat2.plotV()
        viscircles(R_init(2:-1:1), 0.5*Lat2.V_norm, 'Color', 'w', ...
            'EnhanceVisibility', false, 'LineWidth', 0.5);
    end
end
