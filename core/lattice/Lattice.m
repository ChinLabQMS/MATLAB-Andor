 classdef Lattice < BaseObject
    %LATTICE Class for lattice calibration and conversion

    properties (Constant)
        Standard_V1 = [0, 1]
        Standard_V2 = [-1/2*sqrt(3), -1/2]
        TransformStandard_Scale = 10
        TransformStandard_XLimSite = [-25, 25]
        TransformStandard_YLimSite = [-25, 25]
        CalibR_Binarize = true
        CalibR_BinarizeThres = 0.5
        CalibR_MinBinarizeThres = 30
        CalibR_Bootstrapping = false
        CalibR_PlotDiagnostic = false
        CalibV_RFitFFT = 7
        CalibV_CalibR = true
        CalibV_WarnLatNormThres = 0.001
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibO_CalibR = true
        CalibO_CalibR_Bootstrap = false
        CalibO_Sites = Lattice.prepareSite("hex", "latr", 3)
        CalibO_DistanceMetric = "cosine"
        CalibO_NumScores = 5
        CalibO_WarnThresScoreDev = 5
        CalibO_Verbose = false
        CalibO_Debug = false
        CalibO_PlotDiagnostic = false
    end

    properties (SetAccess = immutable)
        ID
        PixelSize          % um
        RealSpacing   % um
    end

    properties (SetAccess = protected)
        K  % Momentum-space reciprocal vectors, 2x2 double
        V  % Real-space lattice vectors, 2x2 double
        R  % Real-space lattice center, 1x2 double
        Rstat  % Statistics generated during calibrating lattice R
        Ostat  % Statistics generated during cross calibrating lattice R
    end

    properties (Dependent, Hidden)
        V_norm
        ImageMagnification
    end
    
    methods
        function Lat = Lattice(id, pixel_size, spacing, options)
            arguments
                id = "Standard"
                pixel_size = 13
                spacing = 0.8815
                options.v1 = Lattice.Standard_V1
                options.v2 = Lattice.Standard_V2
            end
            Lat.ID = id;
            Lat.PixelSize = pixel_size;
            Lat.RealSpacing = spacing;
            if id == "Standard"
                Lat.init([0, 0], [], [options.v1; options.v2], ...
                    "format", "KV")
            end
        end
        
        % Initialize the calibration by
        % - setting the lattice center
        % - (or), specify a FFT peak position for getting K and V
        function init(Lat, R, arg1, arg2, options)
            arguments
                Lat
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
                            [Lat.K, Lat.V] = convertFFTPeak2K(arg1, arg2);
                        else
                            Lat.error("Wrong input format for peak_pos.")
                        end
                    case "KV"
                        if ~isempty(arg1)
                            Lat.K = arg1;
                        else
                            Lat.K = inv(arg2)';
                        end
                        if ~isempty(arg2)
                            Lat.V = arg2;
                        else
                            Lat.V = inv(arg1)';
                        end
                    case "Lat"
                        Lat.K = arg1.K;
                        Lat.V = arg1.V;
                        Lat.R = arg1.R;
                    otherwise
                        Lat.error('Unrecongized input format %s.', options.format)
                end
            end
            if ~isempty(R)
                old_R = Lat.R;
                Lat.R = R;
                if options.verbose
                    Lat.info("Lattice center is set to (%g, %g), originally (%g, %g)", ...
                        R(1), R(2), old_R(1), old_R(2))
                end
            end
        end
        
        % Convert lattice space coordinates to real space
        function [coor, sites] = convert2Real(Lat, sites, options)
            arguments
                Lat
                sites = []
                options.center = Lat.R
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
                lat_corners = (corners - Lat.R)/Lat.V;
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
            coor = sites * Lat.V + options.center;
            % Filter lattice sites outside of a rectangular limit area
            if options.filter
                idx = (coor(:, 1) >= options.x_lim(1)) & ...
                      (coor(:, 1) <= options.x_lim(2) & ...
                      (coor(:, 2) >= options.y_lim(1)) & ...
                      (coor(:, 2) <= options.y_lim(2)));
                coor = coor(idx, :);
                sites = sites(idx, :);
            end
        end
        
        % Convert real-space coordinates to lattice space
        function sites = convert2Lat(Lat, coor)
            sites = (coor - Lat.R) * Lat.K';
        end
        
        % Calibrate lattice center (R) by FFT phase
        function calibrateR(Lat, signal, x_range, y_range, optionsR)
            arguments
                Lat
                signal
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                optionsR.binarize = Lat.CalibR_Binarize
                optionsR.binarize_thres_perct = Lat.CalibR_BinarizeThres
                optionsR.min_binarize_thres = Lat.CalibR_MinBinarizeThres
                optionsR.bootstrapping = Lat.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = Lat.CalibR_PlotDiagnostic
            end
            % If the image is not directly from imaging lattice, do filtering
            if optionsR.binarize
                signal_new = filterSignal(signal, optionsR.binarize_thres_perct, optionsR.min_binarize_thres);
            else
                signal_new = signal;
            end
            signal = mean(signal, 3);
            signal_new = mean(signal_new, 3);
            % Update Lat.R
            Lat.R = Lat.convertFFTPhase2R(signal_new, x_range, y_range);
            Lat.Rstat = getSubStat(Lat, signal_new, x_range, y_range, optionsR.bootstrapping);
            if optionsR.plot_diagnosticR
                figure('Name', 'Lattice R calibration diagnostics')
                subplot(1, 2, 1)
                imagesc2(y_range, x_range, signal, "title", sprintf("%s: Signal", Lat.ID))
                Lat.plot('full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV()
                subplot(1, 2, 2)
                imagesc2(y_range, x_range, signal_new, "title", sprintf("%s: Signal (discrete)", Lat.ID))
                Lat.plot('full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV()
            end
        end
        
        % Calibrate lattice center (R) by FFT phase with cropped signal
        function calibrateRCrop(Lat, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, crop_R);
            Lat.calibrateR(signal, x_range, y_range, varargin{:})
        end

        % Calibrate lattice center (R) by FFT phase with cropped signal,
        % crop radius is in the unit of lattice spacing
        function calibrateRCropSite(Lat, signal, crop_R_site, varargin)
            calibrateRCrop(Lat, signal, crop_R_site * Lat.V_norm, varargin{:})
        end
        
        % Calibrate lattice vectors with FFT, then lattice centers
        function calibrate(Lat, signal, x_range, y_range, optionsV, optionsR)
            arguments
                Lat
                signal
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                optionsV.R_fit = Lat.CalibV_RFitFFT
                optionsV.calib_R = Lat.CalibV_CalibR
                optionsV.warning_rsquared = Lat.CalibV_WarnRSquared
                optionsV.warning_latnorm_thres = Lat.CalibV_WarnLatNormThres                
                optionsV.plot_diagnosticV = Lat.CalibV_PlotDiagnostic
                optionsR.binarize = Lat.CalibR_Binarize
                optionsR.binarize_thres_perct = Lat.CalibR_BinarizeThres
                optionsR.min_binarize_thres = Lat.CalibR_MinBinarizeThres
                optionsR.bootstrapping = Lat.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = Lat.CalibR_PlotDiagnostic
            end
            LatInit = Lat.struct();
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
            peak_init = convertK2FFTPeak(xy_size, Lat.K);
            [peak_pos, peak_info] = fitFFTPeaks(signal_fft, peak_init, optionsV.R_fit);
            for peak = peak_info
                if peak.GOF.rsquare < optionsV.warning_rsquared
                    Lat.warn('FFT peak fit at (%5.2f, %5.2f) might be off (rsquare=%.3f).', ...
                        peak.PeakFit.x0, peak.PeakFit.y0, peak.GOF.rsquare)
                end
            end
            % Use fitted FFT peak position to get new calibration
            [Lat.K, Lat.V] = convertFFTPeak2K(xy_size, peak_pos);
            % Re-calibrate lattice centers to snap it into grid
            if optionsV.calib_R
                argsR = namedargs2cell(optionsR);
                Lat.calibrateR(signal, x_range, y_range, argsR{:})
            end
            % Compute lattice vector norm changes
            VDis = vecnorm(Lat.V'-LatInit.V')./vecnorm(LatInit.V');
            if any(VDis > optionsV.warning_latnorm_thres)
                Lat.warn("Lattice vector length changed significantly by %.2f%%.",...
                         100*(max(VDis)))
            end
            if optionsV.plot_diagnosticV
                plotFFT(signal_fft, peak_init, peak_pos, peak_info, Lat.ID)
            end
        end

        % Calibrate lattice vectors with FFT, then lattice centers with
        % cropped signal
        function calibrateCrop(Lat, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, crop_R);
            Lat.calibrate(signal, x_range, y_range, varargin{:})
        end

        % Calibrate lattice vectors with FFT, then lattice centers with
        % cropped signal, crop radius is in the unit of lattice spacing
        function calibrateCropSite(Lat, signal, crop_R_site, varargin)
            calibrateCrop(Lat, signal, crop_R_site * Lat.V_norm, varargin{:})
        end

        % Convert coordinates in Lat space to Lat2 space
        function [coor2, sites] = transform(Lat, Lat2, coor, options)
            arguments
                Lat
                Lat2
                coor = []
                options.round_output = true
            end
            [coor2, sites] = Lat2.convert2Real(Lat.convert2Lat(coor), 'filter', false);
            if options.round_output
                coor2 = round(coor2);
            end
        end

        % Cross conversion of one image from Lat to Lat2
        % for all pixels within (x_range2, y_range2) in Lat2 space
        function transformed2 = transformSignal(Lat, Lat2, x_range2, y_range2, ...
                signal, x_range, y_range)
            arguments
                Lat
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
            % Corresponding pixel position in Lat camera space
            coor = Lat2.transform(Lat, coor2, "round_output", true);
            % Look up the values at corresponding pixels
            idx = (coor(:, 1) >= x_range(1)) & (coor(:, 1) <= x_range(end)) ...
                & (coor(:, 2) >= y_range(1)) & (coor(:, 2) <= y_range(end));
            transformed2 = zeros(length(x_range2), length(y_range2));
            transformed2(idx) = signal(coor(idx, 1) - x_range(1) + 1 ...
                + (coor(idx, 2) - y_range(1)) * size(signal, 1));
        end
        
        % Cross conversion of one image from Lat space to a standard Lat2
        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandard( ...
                Lat, signal, x_range, y_range, options1, options2)
            arguments
                Lat
                signal 
                x_range 
                y_range
                options1.v1 = Lattice.Standard_V1
                options1.v2 = Lattice.Standard_V2
                options2.scale = Lat.TransformStandard_Scale
                options2.x_lim = Lat.TransformStandard_XLimSite
                options2.y_lim = Lat.TransformStandard_YLimSite
            end
            args = namedargs2cell(options1);
            Lat2 = Lattice('Standard', args{:});
            xlim = options2.x_lim;
            ylim = options2.y_lim;
            x_range2 = xlim(1): 1/options2.scale: xlim(2);
            y_range2 = ylim(1): 1/options2.scale: ylim(2);
            transformed2 = Lat.transformSignal(Lat2, x_range2, y_range2, signal, x_range, y_range);
        end

        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCrop(Lat, signal, crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, crop_R);
            [transformed2, x_range2, y_range2, Lat2] = Lat.transformSignalStandard(signal, x_range, y_range, varargin{:});
        end

        function [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCropSite(Lat, signal, crop_R_site, varargin)
            [transformed2, x_range2, y_range2, Lat2] = transformSignalStandardCrop(Lat, signal, crop_R_site * Lat.V_norm, varargin{:});
        end

        % Calibrate the origin of Lat to Lat2 based on signal overlapping
        function calibrateO(Lat, Lat2, signal, signal2, ...
                x_range, y_range, x_range2, y_range2, options)
            arguments
                Lat
                Lat2
                signal
                signal2
                x_range {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                x_range2 {mustBeValidRange(signal2, 1, x_range2)} = 1:size(signal2, 1)
                y_range2 {mustBeValidRange(signal2, 2, y_range2)} = 1:size(signal2, 2)
                options.calib_R = Lat.CalibO_CalibR
                options.calib_R_bootstrap = Lat.CalibO_CalibR_Bootstrap
                options.sites = Lat.CalibO_Sites
                options.metric = Lat.CalibO_DistanceMetric
                options.debug = Lat.CalibO_Debug
                options.verbose = Lat.CalibO_Verbose
                options.num_scores = Lat.CalibO_NumScores
                options.warn_thres_score_dev = Lat.CalibO_WarnThresScoreDev
                options.plot_diagnosticO = Lat.CalibO_PlotDiagnostic
            end
            Lat.checkInitialized()
            Lat2.checkInitialized()
            if options.calib_R
                Lat.calibrateR(signal, x_range, y_range, "bootstrapping", options.calib_R_bootstrap)
                Lat2.calibrateR(signal2, x_range2, y_range2, "bootstrapping", options.calib_R_bootstrap)
            end
            R_init = Lat.R;
            num_sites = size(options.sites, 1);
            score.Site = options.sites;
            score.Center = Lat.convert2Real(options.sites, "filter", false);
            score.SignalDist = nan(num_sites, 1);
            best_score = inf;
            best_transformed = [];
            for i = 1: num_sites
                Lat.R = score.Center(i, :);
                transformed = Lat2.transformSignal(Lat, x_range, y_range, signal2, x_range2, y_range2);
                score.SignalDist(i) = pdist2(signal(:)', transformed(:)', options.metric);
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
            Lat.R = best.Center;
            Lat.Ostat = table2struct(best);
            Lat.Ostat.BestTransformed = best_transformed;
            Lat.Ostat.OriginalSignal = signal;
            info_str = sprintf("Center is calibrated to %s, now at (%d, %d) = (%5.2f, %5.2f) px, initially at (%5.2f, %5.2f) px, min dist = %5.3f among (%s).", ...
                    Lat2.ID, best.Site(1), best.Site(2), best.Center(1), best.Center(2), ...
                    R_init(1), R_init(2), best.SignalDist, join(string(compose('%4.3f', min_val)), ", "));
            if all(best.Site == [0, 0]) && ...
                    abs(best.SignalDist - mean(others.SignalDist))/std(others.SignalDist) > options.warn_thres_score_dev
                if options.verbose
                    Lat.info("%s", info_str)
                end
            else
                Lat.warn("%s", info_str)
            end
            if options.plot_diagnosticO
                plotSimilarityMap(x_range, y_range, score, best)
                plotTransformation(Lat, Lat2, R_init, signal, signal2, best_transformed, ...
                    x_range, y_range, x_range2, y_range2)
            end
            if options.debug  % Reset to initial R
                Lat.R = R_init;
            end
        end

        % Calibrate the origin of Lat to Lat2 based on signal overlapping,
        % with cropped signal
        function calibrateOCrop(Lat, Lat2, signal, signal2, ...
                crop_R, varargin)
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, crop_R);
            [signal2, x_range2, y_range2] = prepareBox(signal2, Lat2.R, crop_R);
            Lat.calibrateO(Lat2, signal, signal2, x_range, y_range, x_range2, y_range2, varargin{:})
        end

        % Calibrate the origin of Lat to Lat2 based on signal overlapping,
        % with cropped signal, crop radius is in the unit of lattice
        % spacing
        function calibrateOCropSite(Lat, Lat2, signal, signal2, ...
                crop_R_site, varargin)
            Lat.calibrateOCrop(Lat2, signal, signal2, crop_R_site * Lat.V_norm, varargin{:})
        end

        % Overlaying the lattice sites
        function varargout = plot(Lat, varargin, opt1, opt2)
            arguments
                Lat
            end
            arguments (Repeating)
                varargin
            end
            arguments
                opt1.center = Lat.R
                opt1.filter = true
                opt1.x_lim = [1, 1440]
                opt1.y_lim = [1, 1440]
                opt1.full_range = false
                opt2.color = "r"
                opt2.norm_radius = 0.1
                opt2.add_origin = true
                opt2.origin_radius = 0.5
                opt2.line_width = 0.5
            end
            if isempty(varargin)
                ax = gca();
                sites = Lattice.prepareSite('hex', 'latr', 20);
            elseif isscalar(varargin)
                ax = gca();
                sites = varargin{1};
            elseif length(varargin) == 2
                ax = varargin{1};
                sites = varargin{2};
            else
                Lat.error("Unsupported number of input positional arguments.")
            end
            Lat.checkInitialized()
            opt1.remove_origin = opt2.add_origin;
            args = namedargs2cell(opt1);
            corr = Lat.convert2Real(sites, args{:});
            % Use a different radius to display origin
            if opt2.add_origin
                radius = [repmat(opt2.norm_radius * Lat.V_norm, size(corr, 1), 1);
                          opt2.origin_radius * Lat.V_norm];
                corr = [corr; opt1.center];
            else
                radius = opt2.norm_radius * Lat.V_norm;
            end
            h = viscircles(ax, corr(:, 2:-1:1), radius, ...
                'Color', opt2.color, 'EnhanceVisibility', false, 'LineWidth', opt2.line_width);
            % Output the handle to the group of circles
            if nargout == 1
                varargout{1} = h;
            end
        end
        
        % Plot lattice vectors
        function varargout = plotV(Lat, ax, options)
            arguments
                Lat
                ax = gca()
                options.origin = Lat.R
                options.scale = 1
                options.add_legend = true
            end
            Lat.checkInitialized()
            c_obj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            hold(ax,'on');
            h(1) = quiver(ax, options.origin(2), options.origin(1), options.scale * Lat.V(1, 2), options.scale * Lat.V(1, 1), 'off', ...
                'LineWidth', 2, 'DisplayName', sprintf("%s: V1", Lat.ID), 'MaxHeadSize', 10, 'Color', 'r');
            h(2) = quiver(ax, options.origin(2), options.origin(1), options.scale * Lat.V(2, 2), options.scale * Lat.V(2, 1), 'off', ...
                'LineWidth', 2, 'DisplayName', sprintf("%s: V2", Lat.ID), 'MaxHeadSize', 10, 'Color', 'm');
            if options.add_legend
                legend('Interpreter', 'none')
            end
            if nargout == 1
                varargout{1} = h;
            end
        end
        
        % Convert the current K vector to an expected FFT peak location
        function peak_pos = convert2FFTPeak(Lat, xy_size)
            Lat.checkInitialized()
            peak_pos = convertK2FFTPeak(xy_size, Lat.K);
        end
        
        % Convert FFT phase to lattice center R
        function R = convertFFTPhase2R(Lat, signal, x_range, y_range)
            Lat.checkInitialized()
            % Extract lattice center coordinates from phase at FFT peak
            [Y, X] = meshgrid(y_range, x_range);
            phase_vec = zeros(1,2);
            for i = 1:2
                phase_mask = exp(-1i*2*pi*(Lat.K(i,1)*X + Lat.K(i,2)*Y));
                phase_vec(i) = angle(sum(phase_mask.*signal, 'all'));
            end
            R = (round(Lat.R*Lat.K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * Lat.V;
        end

        % Display lattice calibration details
        function disp(Lat)
            fprintf('%s: \n', Lat.getStatusLabel())
            if ~isempty(Lat.K)
                s = Lat.struct(["ID", "PixelSize", "RealSpacing", "ImageMagnification"]);
                disp(s)
            else
                s = Lat.struct(["ID", "PixelSize", "RealSpacing"]);
                disp(s)
                fprintf('Lattice calibration is not initialized.\n\n')
                return
            end
            V1 = Lat.V(1, :);
            V2 = Lat.V(2, :);
            V3 = V1 + V2;            
            fprintf('Calibration result:\n')
            fprintf('\tR  = (%7.2f, %7.2f) px\n', Lat.R(1), Lat.R(2))
            fprintf('\tV1 = (%7.2f, %7.2f) px,\t|V1| = %7.2f px\n', V1(1), V1(2), norm(V1))
            fprintf('\tV2 = (%7.2f, %7.2f) px,\t|V2| = %7.2f px\n', V2(1), V2(2), norm(V2))
            fprintf('\tV3 = (%7.2f, %7.2f) px,\t|V3| = %7.2f px\n', V3(1), V3(2), norm(V3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(V1*V2'/(norm(V1)*norm(V2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n\n', acosd(V1*V3'/(norm(V1)*norm(V3))))
        end

        function val = get.V_norm(Lat)
            Lat.checkInitialized()
            val = mean([norm(Lat.V(1, :)), norm(Lat.V(2, :))]);
        end

        function val = get.ImageMagnification(Lat)
            val = (Lat.V_norm * Lat.PixelSize) / Lat.RealSpacing;
        end

        % function val = get.RayleighResolution(Lat)
        %     val = 0.61 * Lat.ImagingWavelength / Lat.NA * Lat.ImageMagnification / Lat.PixelSize;
        % end
        % 
        % function val = get.RayleighResolutionGaussSigma(Lat)
        %     val = Lat.RayleighResolution / 2.9;
        % end

        function s = struct(Lat, fields)
            arguments
                Lat
                fields = ["K", "V", "R", "ID"]
            end
            s = struct@BaseObject(Lat, fields);
        end
    end
    
    methods (Access = protected, Hidden)
        function checkInitialized(Lat)
            if isempty(Lat.K)
                Lat.error("Lattice details are not initialized.")
            end
        end

        function updateResolution(obj)
            obj.PointSource.config("RayleighResolution", obj.RayleighResolution)
        end

        function label = getStatusLabel(Lat)
            label = sprintf("%s (%s)", class(Lat), Lat.ID);
        end
    end

    methods (Static)
        function Lat = struct2obj(s, ID, options)
            arguments
                s (1, 1) struct
                ID (1, 1) string = s.ID
                options.verbose (1, 1) logical = true
            end
            Lat = Lattice(ID);
            Lat.init(s.R, s.K, s.V, 'format', "KV")
            if options.verbose
                Lat.info("Object loaded from structure.")
            end
        end

        function sites = prepareSite(format, options)
            arguments
                format (1, 1) string = "hex"
                options.latx_range = -10:10
                options.laty_range = -10:10
                options.latr = 10
            end    
            switch format
                case 'rect'
                    [Y, X] = meshgrid(options.laty_range, options.latx_range);
                    sites = [X(:), Y(:)];
                case 'hex'
                    r = options.latr;
                    [Y, X] = meshgrid(-r:r, -r:r);
                    idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
                    sites = [X(idx), Y(idx)];
                otherwise
                    error("Not implemented")
            end
        end

        function checkDiff(Lat, Lat2, label, label2)
            arguments
                Lat
                Lat2
                label = "old"
                label2 = "new"
            end
            V = [Lat.V; Lat.V(1, :) + Lat.V(2, :)];
            V2 = [Lat2.V; Lat2.V(1, :) + Lat2.V(2, :)];
            fprintf('Difference between %s (%s) and %s (%s):\n', Lat.ID, label, Lat2.ID, label2)
            fprintf('\t\t R = (%7.2f, %7.2f),\t R'' = (%7.2f, %7.2f),\tDiff = (%7.2f, %7.2f)\n', ...
                    Lat.R(1), Lat.R(2), Lat2.R(1), Lat2.R(2), Lat2.R(1) - Lat.R(1), Lat2.R(2) - Lat.R(2))
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

% Filter the signal with a given threshold percentage and min threshold
function signal_modified = filterSignal(signal, binarize_thres, min_binarize_thres)
    signal_modified = signal;
    thres = max(binarize_thres * max(signal(:)), min_binarize_thres);
    signal_modified((signal_modified < thres)) = 0;
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
function res = getSubStat(Lat, signal, x_range, y_range, if_bootstrap)
    res.R1 = Lat.R(1);
    res.R2 = Lat.R(2);
    LatR = Lat.R / Lat.V;
    res.LatR1 = LatR(1);
    res.LatR2 = LatR(2);
    if ~if_bootstrap
        return
    end
    s = partitionSignal4(signal, x_range, y_range);
    R_Sub = nan(length(s), 2);
    for i = 1:length(s)
        R_Sub(i, :) = Lat.convertFFTPhase2R(s(i).Signal, s(i).XRange, s(i).YRange);
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
    LatR_Sub = R_Sub / Lat.V;
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

function plotTransformation(Lat, Lat2, R_init, signal, signal2, best_transformed, ...
                x_range, y_range, x_range2, y_range2)
    figure('Name', 'Cross-calibrated transformed images')
    subplot(1, 3, 1)
    imagesc2(y_range2, x_range2, signal2, "title", sprintf("%s: reference", Lat2.ID))
    Lat2.plot()
    Lat2.plotV()
    subplot(1, 3, 2)
    imagesc2(y_range, x_range, signal, "title", sprintf("%s: calibrated", Lat.ID))
    Lat.plot()
    Lat.plotV()
    viscircles(R_init(2:-1:1), 0.5*Lat.V_norm, 'Color', 'w', ...
        'EnhanceVisibility', false, 'LineWidth', 0.5);
    subplot(1, 3, 3)
    imagesc2(y_range, x_range, best_transformed, "title", sprintf("%s: best transformed from %s", Lat.ID, Lat2.ID))
    Lat.plot()
    Lat.plotV()
    viscircles(R_init(2:-1:1), 0.5*Lat.V_norm, 'Color', 'w', ...
        'EnhanceVisibility', false, 'LineWidth', 0.5);
end

% Function for preserving hold behavior on exit
function preserveHold(was_hold_on,ax)
    if ~was_hold_on
        hold(ax,'off');
    end
end
