 classdef Lattice < BaseObject
    %LATTICE Class for lattice calibration and conversion

    properties (Constant)
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
        CalibO_Sites = Lattice.prepareSite("hex", "latr", 3)
        CalibO_DistanceMetric = "cosine"
        CalibO_NumScores = 5
        CalibO_VerboseStep = false
        CalibO_Verbose = true
        CalibO_Debug = false
        CalibO_PlotDiagnostic = false
    end

    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = protected)
        K  % Momentum-space reciprocal vectors, 2x2 double
        V  % Real-space lattice vectors, 2x2 double
        R  % Real-space lattice center, 1x2 double
        Rstat
    end

    properties (Dependent, Hidden)
        V_norm
    end
    
    methods
        function Lat = Lattice(ID)
            arguments
                ID = "Test"
            end
            Lat.ID = ID;            
        end
        
        % Initialize the calibration by
        % - setting the lattice center
        % - (or), specify a FFT peak position for getting K and V
        function init(Lat, R, size_or_K, pos_or_V, options)
            arguments
                Lat
                R = []
                size_or_K = []
                pos_or_V = []
                options.format = "peak_pos"
            end
            if ~isempty(pos_or_V) && ~isempty(size_or_K)
                if options.format == "peak_pos"
                    [Lat.K, Lat.V] = convertFFTPeak2K(size_or_K, pos_or_V);
                elseif options.format == "KV"
                    Lat.K = size_or_K;
                    Lat.V = pos_or_V;
                end
            end
            if ~isempty(R)
                Lat.R = R;
            end
        end
        
        % Convert lattice space coordinates to real space
        function [coor, sites] = convert2Real(Lat, sites, options)
            arguments
                Lat
                sites = []
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
            coor = sites * Lat.V + Lat.R;
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
                optionsR.binarize_thres = Lat.CalibR_BinarizeThres
                optionsR.min_binarize_thres = Lat.CalibR_MinBinarizeThres
                optionsR.bootstrapping = Lat.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = Lat.CalibR_PlotDiagnostic
            end
            signal_modified = signal;
            % If the image is not directly from imaging lattice, do filtering
            if Lat.ID ~= "Zelux"
                thres = max(optionsR.binarize_thres * max(signal(:)), optionsR.min_binarize_thres);
                signal_modified((signal_modified < thres)) = 0;
            end
            % Update Lat.R
            Lat.R = Lat.convertFFTPhase2R(signal_modified, x_range, y_range);
            % Use 4 equal size sub-area to get statistics
            if optionsR.bootstrapping
                Lat.Rstat = getSubStat(Lat, signal_modified, x_range, y_range);
            else
                Lat.Rstat = [];
            end
            if optionsR.plot_diagnosticR
                figure
                imagesc2(y_range, x_range, signal_modified, "title", sprintf("%s: Signal (modified)", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
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
                optionsR.binarize_thres = Lat.CalibR_BinarizeThres
                optionsR.min_binarize_thres = Lat.CalibR_MinBinarizeThres
                optionsR.bootstrapping = Lat.CalibR_Bootstrapping
                optionsR.plot_diagnosticR = Lat.CalibR_PlotDiagnostic
            end
            LatInit = Lat.struct();
            signal_fft = abs(fftshift(fft2(signal)));
            xy_size = size(signal);
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
                figure
                imagesc2(y_range, x_range, signal, "title", sprintf("%s: Signal", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV()
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
            coor = Lat2.transform(Lat, coor2);
            % Look up the values at corresponding pixels
            idx = (coor(:, 1) >= x_range(1)) & (coor(:, 1) <= x_range(end)) ...
                & (coor(:, 2) >= y_range(1)) & (coor(:, 2) <= y_range(end));
            transformed2 = zeros(length(x_range2), length(y_range2));
            transformed2(idx) = signal(coor(idx, 1) - x_range(1) + 1 ...
                + (coor(idx, 2) - y_range(1)) * size(signal, 1));
        end
        
        % Calibrate the origin of Lat to Lat2 based on signal overlapping
        function best_transformed = calibrateO(Lat, Lat2, signal, signal2, ...
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
                options.sites = Lat.CalibO_Sites
                options.metric = Lat.CalibO_DistanceMetric
                options.debug = Lat.CalibO_Debug
                options.verbose_step = Lat.CalibO_VerboseStep
                options.verbose = Lat.CalibO_Verbose
                options.num_scores = Lat.CalibO_NumScores
                options.plot_diagnosticO = Lat.CalibO_PlotDiagnostic
            end
            Lat.checkInitialized()
            Lat2.checkInitialized()
            if options.calib_R
                Lat.calibrateR(signal, x_range, y_range)
                Lat2.calibrateR(signal2, x_range2, y_range2)
            end
            R_init = Lat.R;
            num_sites = size(options.sites, 1);
            score = table('Size', [num_sites, 3], ...
                'VariableTypes', ["doublenan", "doublenan", "doublenan"], ...
                'VariableNames', ["Site", "Center", "SignalDist"]);
            score.Site = options.sites;
            score.Center = Lat.convert2Real(options.sites, "filter", false);
            best_score = inf;
            best_transformed = [];
            for i = 1: num_sites
                Lat.R = score.Center(i, :);
                transformed = Lat2.transformSignal(Lat, x_range, y_range, signal2, x_range2, y_range2);
                score.SignalDist(i) = pdist([signal(:)'; transformed(:)'], options.metric);
                if score.SignalDist(i) < best_score
                    best_score = score.SignalDist(i);
                    best_transformed = transformed;
                end
                if options.verbose_step
                    Lat.info("Trying site (%3d, %3d) at (%5.2f px, %5.2f px), score is %7.3f.", ...
                        score.Site(i, 1), score.Site(i, 2), score.Center(i, 1), score.Center(i, 2), score.SignalDist(i))
                end
            end
            options.num_scores = min(options.num_scores, num_sites);
            [min_val, min_idx] = mink(score.SignalDist, options.num_scores);
            best = score(min_idx(1), :);
            Lat.R = best.Center;
            if options.verbose
                Lat.info("Lattice center is cross-calibrated to %s, initially at (%5.2f px, %5.2f px), now at (%d, %d) = (%5.2f px, %5.2f px), min dist = %7.3f.", ...
                    Lat2.ID, R_init(1), R_init(2), best.Site(1), best.Site(2), best.Center(1), best.Center(2), best.SignalDist)
                Lat.info("Minimum %d distances are %s.", options.num_scores, strip(sprintf('%7.3f ', min_val)))
            end
            if options.plot_diagnosticO
                plotSimilarityMap(x_range, y_range, score, best)
                figure
                subplot(1, 3, 1)
                imagesc2(y_range2, x_range2, signal2, "title", sprintf("%s: reference", Lat2.ID))
                Lat2.plot(options.sites)
                Lat2.plotV()
                subplot(1, 3, 2)
                imagesc2(y_range, x_range, signal, "title", sprintf("%s: calibrated", Lat.ID))
                Lat.plot(options.sites)
                Lat.plotV()
                viscircles(R_init(2:-1:1), 0.5*Lat.V_norm, 'Color', 'w', ...
                    'EnhanceVisibility', false, 'LineWidth', 0.5);
                subplot(1, 3, 3)
                imagesc2(y_range, x_range, best_transformed, "title", sprintf("%s: best transformed from %s", Lat.ID, Lat2.ID))
                Lat.plot(options.sites)
                Lat.plotV()
                viscircles(R_init(2:-1:1), 0.5*Lat.V_norm, 'Color', 'w', ...
                    'EnhanceVisibility', false, 'LineWidth', 0.5);
            end
            if options.debug  % Reset to initial R
                Lat.R = R_init;
            end
        end

        % Calibrate the origin of Lat to Lat2 based on signal overlapping,
        % with cropped signal
        function best_transformed = calibrateOCrop(Lat, Lat2, signal, signal2, ...
                crop_R, crop_R2, varargin)
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, crop_R);
            [signal2, x_range2, y_range2] = prepareBox(signal2, Lat2.R, crop_R2);
            best_transformed = Lat.calibrateO(Lat2, signal, signal2, x_range, y_range, x_range2, y_range2, varargin{:});
        end

        % Calibrate the origin of Lat to Lat2 based on signal overlapping,
        % with cropped signal, crop radius is in the unit of lattice
        % spacing
        function best_transformed = calibrateOCropSite(Lat, Lat2, signal, signal2, ...
                crop_R_site, crop_R2_site, varargin)
            best_transformed = calibrateOCrop(Lat, Lat2, signal, signal2, ...
                crop_R_site * Lat.V_norm, crop_R2_site * Lat2.V_norm, varargin{:});
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
                corr = [corr; Lat.convert2Real([0, 0])];
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
        function plotV(Lat, ax, options)
            arguments
                Lat
                ax = gca()
                options.origin = Lat.R
                options.scale = 1
            end
            Lat.checkInitialized()
            cObj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            hold(ax,'on');
            quiver(ax, options.origin(2), options.origin(1), options.scale * Lat.V(1, 2), options.scale * Lat.V(1, 1), "off", ...
                "LineWidth", 2, "DisplayName", sprintf("%s: V1", Lat.ID), "MaxHeadSize", 10)
            axis image
            quiver(ax, options.origin(2), options.origin(1), options.scale * Lat.V(2, 2), options.scale * Lat.V(2, 1), "off", ...
                "LineWidth", 2, "DisplayName", sprintf("%s: V2", Lat.ID), "MaxHeadSize", 10)
            legend()
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
            if isempty(Lat.K)
                fprintf('%s: Not initialized.\n', Lat.getStatusLabel())
                return
            end
            V1 = Lat.V(1, :);
            V2 = Lat.V(2, :);
            V3 = V1 + V2;
            fprintf('%s: \n\tR  = (%7.2f, %7.2f) px\n', Lat.getStatusLabel(), Lat.R(1), Lat.R(2))
            fprintf('\tV1 = (%7.2f, %7.2f) px,\t|V1| = %7.2f px\n', V1(1), V1(2), norm(V1))
            fprintf('\tV2 = (%7.2f, %7.2f) px,\t|V2| = %7.2f px\n', V2(1), V2(2), norm(V2))
            fprintf('\tV3 = (%7.2f, %7.2f) px,\t|V3| = %7.2f px\n', V3(1), V3(2), norm(V3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(V1*V2'/(norm(V1)*norm(V2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n', acosd(V1*V3'/(norm(V1)*norm(V3))))
        end

        function val = get.V_norm(Lat)
            val = mean([norm(Lat.V(1, :)), norm(Lat.V(2, :))]);
        end

        function s = struct(Lat)
            s = struct@BaseObject(Lat, ["K", "V", "R", "ID"]);
        end
    end
    
    methods (Access = protected, Hidden)
        function checkInitialized(Lat)
            if isempty(Lat.K)
                Lat.error("Lattice details are not initialized.")
            end
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

        function checkDiff(Lat, Lat2)
            V1 = [Lat.V; Lat.V(1, :) + Lat.V(2, :)];
            V2 = [Lat2.V; Lat2.V(1, :) + Lat2.V(2, :)];
            fprintf('Difference between %s and %s:\n', Lat.getStatusLabel(), Lat2.getStatusLabel())
            fprintf('\t R_1 = (%7.2f, %7.2f),\t R_2 = (%7.2f, %7.2f),\tDiff = (%7.2f, %7.2f)\n', ...
                    Lat.R(1), Lat.R(2), Lat2.R(1), Lat2.R(2), Lat.R(1) - Lat2.R(1), Lat.R(2) - Lat2.R(2))
            for i = 1:3
                cos_theta = max(min(dot(V1(i, :),V2(i, :))/(norm(V1(i, :))*norm(V2(i, :))), 1), -1);
                theta_deg = real(acosd(cos_theta));
                fprintf('(%d)\t V_1 = (%7.2f, %7.2f),\t V_2 = (%7.2f, %7.2f),\tAngle<V_1, V_2> = %7.2f deg\n', ...
                    i, V1(i, 1), V1(i, 2), V2(i, 1), V2(i, 2), theta_deg)
            end
            for i = 1:3
                norm1 = norm(V1(i, :));
                norm2 = norm(V2(i, :));
                fprintf('(%d)\t|V11| = %14.2f px,\t|V12| = %14.2f px,\tDiff = %9.2f px (%5.3f%%)\n', ...
                    i, norm1, norm2, norm1 - norm2, 200*(norm1 - norm2)/(norm1 + norm2))
            end
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
function res = getSubStat(Lat, signal, x_range, y_range)
    s = partitionSignal4(signal, x_range, y_range);
    res.R_Sub = nan(length(s), 2);
    for i = 1:length(s)
        res.R_Sub(i, :) = Lat.convertFFTPhase2R(s(i).Signal, s(i).XRange, s(i).YRange);
    end
    res.R1 = Lat.R(1);
    res.R1_Mean = mean(res.R_Sub(:, 1));
    res.R1_Max = max(res.R_Sub(:, 1));
    res.R1_Min = min(res.R_Sub(:, 1));
    res.R1_Std = std(res.R_Sub(:, 1));
    res.R2 = Lat.R(2);
    res.R2_Mean = mean(res.R_Sub(:, 2));
    res.R2_Max = max(res.R_Sub(:, 2));
    res.R2_Min = min(res.R_Sub(:, 2));
    res.R2_Std = std(res.R_Sub(:, 2));
end

% Generate diagnostic plots on the FFT peak fits
function plotFFT(signal_fft, peak_init, peak_pos, peak_info, ID)
    num_peaks = size(peak_pos, 1);
    % Plot FFT magnitude in log scale
    figure("Name", "FFT peak fits diagnostics")
    sgtitle(ID)
    subplot(1, num_peaks + 1, 1)
    imagesc2(log(signal_fft), "title", sprintf("[%s]: log(FFT)", ID))
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
    figure
    imagesc2(y_range, x_range, empty_image, "title", 'Similarity between images from different cameras')
    hold on
    scatter(best.Center(2), best.Center(1), 100, "red")
    scatter(score.Center(:, 2), score.Center(:, 1), 50, score.Similarity, 'filled')
end

% Function for preserving hold behavior on exit
function preserveHold(was_hold_on,ax)
    if ~was_hold_on
        hold(ax,'off');
    end
end

% Input argument validation
function mustBeValidRange(signal, dim, range)
    if size(signal, dim) ~= length(range)
        error("Range does not match signal dimension.")
    end
end
