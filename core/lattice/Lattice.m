 classdef Lattice < BaseObject
    %LATTICE Class for lattice calibration and conversion
    
    properties (SetAccess = {?BaseRunner})
        K                       % Momentum-space reciprocal vectors, 2x2 double
        V                       % Real-space lattice vectors, 2x2 double
        R                       % Real-space lattice center, 1x2 double
    end

    properties (SetAccess = immutable)
        ID
    end

    properties (Dependent, Hidden)
        V1
        V2
        V3
    end
    
    methods
        function Lat = Lattice(ID)
            arguments
                ID (1, 1) string = "Test"
            end
            Lat.ID = ID;            
        end
        
        % Initialize the calibration by
        % - setting the lattice center
        % - (or), specify a FFT peak position for getting K and V
        function init(Lat, center, xy_size, peak_pos)
            arguments
                Lat
                center double = []
                xy_size = []
                peak_pos = []
            end
            if ~isempty(peak_pos) && ~isempty(xy_size)
                [Lat.K, Lat.V] = convertFFTPeak2K(xy_size, peak_pos);
            end
            if ~isempty(center)
                Lat.R = center;
            end
        end
        
        % Convert lattice space coordinates to real space
        function [corr, lat_corr] = convert2Real(Lat, lat_corr, options)
            arguments
                Lat
                lat_corr (:, 2) double = []
                options.filter (1, 1) logical = false
                options.x_lim (1, 2) double = [1, Inf]
                options.y_lim (1, 2) double = [1, Inf]
                options.full_range (1, 1) logical = false
                options.remove_origin (1, 1) logical = false
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
                lat_corr = [X(:), Y(:)];
            end
            % If discard origin in the lattice coordinate
            if options.remove_origin
                idx = lat_corr(:, 1) == 0 & lat_corr(:, 2) == 0;
                lat_corr = lat_corr(~idx, :);
            end
            % Transform coordinates to real space
            corr = lat_corr * Lat.V + Lat.R;
            % Filter lattice sites outside of a rectangular limit area
            if options.filter
                idx = (corr(:, 1) >= options.x_lim(1)) & ...
                      (corr(:, 1) <= options.x_lim(2) & ...
                      (corr(:, 2) >= options.y_lim(1)) & ...
                      (corr(:, 2) <= options.y_lim(2)));
                corr = corr(idx, :);
                lat_corr = lat_corr(idx, :);
            end
        end
        
        % Convert real-space coordinates to lattice space
        function lat_corr = convert2Lat(Lat, corr)
            lat_corr = (corr - Lat.R) * Lat.K';
        end
        
        % Calibrate lattice center (R) by FFT phase
        function varargout = calibrateR(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range (1, :) double {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                options.binarize_thres (1, 1) double = LatCalibConfig.CalibR_BinarizeThres
                options.min_binarize_thres (1, 1) double = LatCalibConfig.CalibR_MinBinarizeThres
                options.bootstrapping (1, 1) logical = LatCalibConfig.CalibR_Bootstrapping
                options.plot_diagnostic (1, 1) logical = LatCalibConfig.CalibR_PlotDiagnostic
            end
            signal_modified = signal;
            % If the image is not directly from imaging lattice, do filtering
            if Lat.ID ~= "Zelux"
                thres = max(options.binarize_thres * max(signal(:)), options.min_binarize_thres);
                signal_modified((signal_modified < thres)) = 0;
            end
            % Update Lat.R
            Lat.R = Lat.convertFFTPhase2R(signal_modified, x_range, y_range);
            % Use 4 equal size sub-area to get uncertainty
            if options.bootstrapping && nargout == 1
                varargout{1} = getSubStat(Lat, signal_modified, x_range, y_range);
            end
            if options.plot_diagnostic
                figure
                Lattice.imagesc(y_range, x_range, signal_modified, "title", sprintf("%s: Signal (modified)", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV()
            end
        end
        
        % Calibrate lattice vectors with FFT, then lattice centers
        function varargout = calibrate(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range (1, :) double {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                options.R_fit = LatCalibConfig.CalibV_RFit
                options.warning_latnorm_thres = LatCalibConfig.CalibV_WarnLatNormThres
                options.warning_rsquared = LatCalibConfig.CalibV_WarnRSquared
                options.binarize_thres (1, 1) double = LatCalibConfig.CalibR_BinarizeThres
                options.plot_diagnosticR (1, 1) logical = LatCalibConfig.CalibR_PlotDiagnostic
                options.plot_diagnosticV (1, 1) logical = LatCalibConfig.CalibV_PlotDiagnostic
            end
            LatInit = Lat.struct();
            signal_fft = abs(fftshift(fft2(signal)));
            xy_size = size(signal);

            % Start from initial calibration, find FFT peaks
            peak_init = convertK2FFTPeak(xy_size, Lat.K);
            [peak_pos, all_peak_fit] = fitFFTPeaks(Lat, signal_fft, peak_init, ...
                "R_fit", options.R_fit, "warning_rsquared", options.warning_rsquared);
            
            % Use fitted FFT peak position to get new calibration
            [Lat.K, Lat.V] = convertFFTPeak2K(xy_size, peak_pos);
            Lat.calibrateR(signal, x_range, y_range, ...
                "binarize_thres", options.binarize_thres, "plot_diagnostic", options.plot_diagnosticR)
            if nargout == 1  % return new FFT peak positions
                varargout{1} = peak_pos;
            end
            VDis = vecnorm(Lat.V'-LatInit.V')./vecnorm(LatInit.V');
            if any(VDis > options.warning_latnorm_thres)
                Lat.warn("Lattice vector length changed significantly by %.2f%%.",...
                         100*(max(VDis)))
            end
            if options.plot_diagnosticV
                plotFFT(signal_fft, peak_init, peak_pos, all_peak_fit, Lat.ID)
                figure
                Lattice.imagesc(y_range, x_range, signal, "title", sprintf("%s: Signal", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV()
            end
        end

        % Convert coordinates in Lat space to Lat2 space
        function [corr2, lat_corr] = transform(Lat, Lat2, corr, options)
            arguments
                Lat (1, 1) Lattice
                Lat2 (1, 1) Lattice
                corr (:, 2) double = []
                options.round_corr (1, 1) logical = true
            end
            [corr2, lat_corr] = Lat2.convert2Real(Lat.convert2Lat(corr), 'filter', false);
            if options.round_corr
                corr2 = round(corr2);
            end
        end

        % Cross conversion of one image from Lat to Lat2
        % for all pixels within (x_range2, y_range2) in Lat2 space
        function transformed2 = transformSignal(Lat, Lat2, x_range2, y_range2, ...
                signal, x_range, y_range)
            arguments
                Lat (1, 1) Lattice
                Lat2 (1, 1) Lattice
                x_range2 (1, :) double
                y_range2 (1, :) double
                signal (:, :) double
                x_range (1, :) double {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
                y_range (1, :) double {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
            end
            % All pixels in Lat2 camera space
            [Y2, X2] = meshgrid(y_range2, x_range2);
            corr2 = [X2(:), Y2(:)];
            % Corresponding pixel position in Lat camera space
            corr = Lat2.transform(Lat, corr2);
            % Look up the values at corresponding pixels
            idx = (corr(:, 1) >= x_range(1)) & (corr(:, 1) <= x_range(end)) ...
                & (corr(:, 2) >= y_range(1)) & (corr(:, 2) <= y_range(end));
            transformed2 = zeros(length(x_range2), length(y_range2));
            transformed2(idx) = signal(corr(idx, 1) - x_range(1) + 1 ...
                + (corr(idx, 2) - y_range(1)) * size(signal, 1));
        end
        
        % Calibrate the origin of Lat to Lat2 based on signal overlapping
        function varargout = calibrateO(Lat, Lat2, signal, signal2, ...
                x_range, y_range, x_range2, y_range2, options)
            arguments
                Lat (1, 1) Lattice
                Lat2 (1, 1) Lattice
                signal (:, :) double
                signal2 (:, :) double
                x_range (1, :) double {mustBeValidRange(signal, 1, x_range)} = 1:size(signal, 1)
                y_range (1, :) double {mustBeValidRange(signal, 2, y_range)} = 1:size(signal, 2)
                x_range2 (1, :) double {mustBeValidRange(signal2, 1, x_range2)} = 1:size(signal2, 1)
                y_range2 (1, :) double {mustBeValidRange(signal2, 2, y_range2)} = 1:size(signal2, 2)
                options.sites = LatCalibConfig.CalibO_Sites
                options.debug (1, 1) logical = LatCalibConfig.CalibO_Debug
                options.verbose (1, 1) logical = LatCalibConfig.CalibO_Verbose
                options.plot_diagnostic (1, 1) logical = LatCalibConfig.CalibO_PlotDiagnostic
            end
            best_score = -1;
            best_site = [];
            best_center = [];
            best_transformed = [];
            R_init = Lat.R;
            Lat.info("Current lattice center = (%4.3f px, %4.3f px).", Lat.R(1), Lat.R(2))
            num_sites = size(options.sites, 1);
            sites_corr = Lat.convert2Real(options.sites, "filter", false);
            site_scores = zeros(num_sites, 1);
            for i = 1: num_sites
                site = options.sites(i, :);
                site_corr = sites_corr(i, :);
                Lat.R = site_corr;
                transformed = Lat2.transformSignal(Lat, x_range, y_range, signal2, x_range2, y_range2);
                site_scores(i) = 1 - pdist2(signal(:)', transformed(:)', "cosine");
                if site_scores(i) > best_score
                    best_score = site_scores(i);
                    best_site = site;
                    best_center = site_corr;
                    best_transformed = transformed;
                end
                if options.verbose
                    Lat.info("Trying site (%3d, %3d) at (%5.2f px, %5.2f px), score is %4.3f.", ...
                        site(1), site(2), site_corr(1), site_corr(2), site_scores(i))
                end
            end
            if isempty(best_center)
                Lat.R = R_init;
                Lat.error("Cross calibration failed, no score above 0 found.")
            end
            Lat.R = best_center;
            Lat.info("Lattice center is cross-calibrated to [%s]. Maximum cosine similarity is %4.3f at site (%d, %d) = (%4.3f px, %4.3f px).", ...
                Lat2.ID, best_score, best_site(1), best_site(2), best_center(1), best_center(2))
            if nargout == 1
                varargout{1} = best_transformed;
            end
            if options.plot_diagnostic
                empty_image = zeros(length(x_range), length(y_range));
                figure
                Lattice.imagesc(y_range, x_range, empty_image, "title", 'Similarity between images from different cameras')
                hold on
                scatter(best_center(2), best_center(1), 100, "red")
                scatter(sites_corr(:, 2), sites_corr(:, 1), 50, site_scores, 'filled')
                clim([min(site_scores), max(site_scores)])

                figure
                subplot(1, 3, 1)
                Lattice.imagesc(y_range2, x_range2, signal2, "title", sprintf("%s: reference", Lat2.ID))
                Lat2.plot(options.sites)
                Lat2.plotV()
                subplot(1, 3, 2)
                Lattice.imagesc(y_range, x_range, signal, "title", sprintf("%s: calibrated", Lat.ID))
                Lat.plot(options.sites)
                Lat.plotV()
                viscircles(R_init(2:-1:1), 0.5*norm(Lat.V1), 'Color', 'w', ...
                    'EnhanceVisibility', false, 'LineWidth', 0.5);
                subplot(1, 3, 3)
                Lattice.imagesc(y_range, x_range, best_transformed, "title", sprintf("%s: best transformed from %s", Lat.ID, Lat2.ID))
                Lat.plot(options.sites)
                Lat.plotV()
                viscircles(R_init(2:-1:1), 0.5*norm(Lat.V1), 'Color', 'w', ...
                    'EnhanceVisibility', false, 'LineWidth', 0.5);
            end
            if options.debug  % Reset to initial R
                Lat.R = R_init;
            end
        end

        % Overlaying the lattice sites
        function varargout = plot(Lat, lat_corr, options)
            arguments
                Lat
                lat_corr (:, 2) double = Lattice.prepareSite('hex', 'latr', 20)
                options.filter (1, 1) logical = true
                options.x_lim (1, 2) double = [1, 1440]
                options.y_lim (1, 2) double = [1, 1440]
                options.full_range (1, 1) logical = false
                options.ax = gca()
                options.color (1, 1) string = "r"
                options.norm_radius (1, 1) double = 0.1
                options.add_origin (1, 1) logical = true
                options.origin_radius (1, 1) double = 0.5
                options.line_width (1, 1) double = 0.5
            end
            corr = Lat.convert2Real(lat_corr, "filter", options.filter, "full_range", options.full_range, ...
                "x_lim", options.x_lim, "y_lim", options.y_lim, "remove_origin", options.add_origin);
            % Use a different radius to display origin
            if options.add_origin
                radius = [repmat(options.norm_radius * norm(Lat.V1), size(corr, 1), 1);
                    options.origin_radius * norm(Lat.V1)];
                corr = [corr; Lat.convert2Real([0, 0])];
            else
                radius = options.norm_radius * norm(Lat.V1);
            end
            h = viscircles(options.ax, corr(:, 2:-1:1), radius, ...
                'Color', options.color, 'EnhanceVisibility', false, 'LineWidth', options.line_width);
            % Output the handle to the group of circles
            if nargout == 1
                varargout{1} = h;
            end
        end
        
        % Plot lattice vectors
        function plotV(Lat, options)
            arguments
                Lat
                options.ax = gca()
                options.origin (1, 2) double = Lat.R
                options.scale (1, 1) double = 1
            end
            cObj = onCleanup(@()preserveHold(ishold(options.ax), options.ax)); % Preserve original hold state
            hold(options.ax,'on');
            quiver(options.ax, options.origin(2), options.origin(1), options.scale * Lat.V1(2), options.scale * Lat.V1(1), "off", ...
                "LineWidth", 2, "DisplayName", sprintf("%s: V1", Lat.ID), "MaxHeadSize", 10)
            axis image
            quiver(options.ax, options.origin(2), options.origin(1), options.scale * Lat.V2(2), options.scale * Lat.V2(1), "off", ...
                "LineWidth", 2, "DisplayName", sprintf("%s: V2", Lat.ID), "MaxHeadSize", 10)
            legend()
        end
        
        % Convert the current K vector to an expected FFT peak location
        function peak_pos = convert2FFTPeak(Lat, xy_size)
            if ~isempty(Lat.K)
                peak_pos = convertK2FFTPeak(xy_size, Lat.K);
            else
                Lat.error("Lattice vector is not initialized.")
            end
        end
        
        % Convert FFT phase to lattice center R
        function R = convertFFTPhase2R(Lat, signal, x_range, y_range)
            if isempty(Lat.K)
                Lat.error("Please calibrate lattice vector before calibrating center.")
            end
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
            if isempty(Lat.V)
                fprintf('%s: Details unset\n', Lat.getStatusLabel())
                return
            end
            v1 = Lat.V1;
            v2 = Lat.V2;
            v3 = Lat.V3;
            fprintf('%s: \n\tR  = (%7.2f, %7.2f) px\n', Lat.getStatusLabel(), Lat.R(1), Lat.R(2))
            fprintf('\tV1 = (%7.2f, %7.2f) px,\t|V1| = %7.2f px\n', v1(1), v1(2), norm(v1))
            fprintf('\tV2 = (%7.2f, %7.2f) px,\t|V2| = %7.2f px\n', v2(1), v2(2), norm(v2))
            fprintf('\tV3 = (%7.2f, %7.2f) px,\t|V3| = %7.2f px\n', v3(1), v3(2), norm(v3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(v1*v2'/(norm(v1)*norm(v2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n', acosd(v1*v3'/(norm(v1)*norm(v3))))
        end
        
        function val = get.V1(Lat)
            if isempty(Lat.V)
                val = [];
                return
            end
            val = Lat.V(1,:);
        end

        function val = get.V2(Lat)
            if isempty(Lat.V)
                val = [];
                return
            end
            val = Lat.V(2,:);
        end

        function val = get.V3(Lat)
            if isempty(Lat.V)
                val = [];
                return
            end
            val = Lat.V1 + Lat.V2;
        end
    end
    
    methods (Access = protected, Hidden)
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
            Lat = BaseRunner.struct2obj(s, Lattice(ID), "prop_list", ["K", "V", "R"], ...
                'verbose', options.verbose);
        end

        function lat_corr = prepareSite(format, options)
            arguments
                format (1, 1) string = "hex"
                options.latx_range = -10:10
                options.laty_range = -10:10
                options.latr = 10
            end    
            switch format
                case 'rect'
                    [Y, X] = meshgrid(options.laty_range, options.latx_range);
                    lat_corr = [X(:), Y(:)];
                case 'hex'
                    r = options.latr;
                    [Y, X] = meshgrid(-r:r, -r:r);
                    idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
                    lat_corr = [X(idx), Y(idx)];
                otherwise
                    error("Not implemented")
            end
        end

        function imagesc(varargin, options)
            arguments (Repeating)
                varargin
            end
            arguments
                options.title (1, 1) string = ""
            end
            imagesc(varargin{:})
            axis image
            colorbar
            title(options.title)
        end

        function checkDiff(Lat, Lat2)
            V1 = [Lat.V; Lat.V3];
            V2 = [Lat2.V; Lat2.V3];
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
function [peak_pos, all_peak_fit] = fitFFTPeaks(Lat, FFT, peak_init, options)
    arguments
        Lat
        FFT (:, :) double
        peak_init (:, 2) double
        options.R_fit (1, 1) double
        options.warning_rsquared (1, 1) double = 0.5
        options.plot_fftpeaks (1, 1) logical = false
    end
    peak_pos = peak_init;
    num_peaks = size(peak_init, 1);
    all_peak_fit = cell(1, num_peaks);
    rx = options.R_fit(1);
    ry = options.R_fit(end);
    for i = 1:num_peaks
        center = round(peak_init(i, :));
        peak_data = prepareBox(FFT, center, [rx, ry]);        
        % Fitting FFT peaks
        [PeakFit,GOF,X,Y,Z] = fitGauss2D(peak_data, ...
            "x_range", -rx:rx, "y_range", -ry:ry, "offset", "linear");
        all_peak_fit{i} = {PeakFit,[X,Y],Z,GOF};
        if GOF.rsquare < options.warning_rsquared
            Lat.warn('FFT peak fit might be off (rsquare=%.3f).', GOF.rsquare)
        end
        peak_pos(i, :) = [PeakFit.x0, PeakFit.y0] + center;
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
    x_idx = [x_idx1; x_idx1; x_idx2; x_idx2];
    y_idx = [y_idx1; y_idx2; y_idx1; y_idx2];
    x_range_list = x_range(x_idx);
    y_range_list = y_range(y_idx);
    s(4) = struct();
    for i = 1:4
        s(i).XRange = x_range_list(i, :);
        s(i).YRange = y_range_list(i, :);
        s(i).Signal = signal(x_idx(i, :), y_idx(i, :));
    end
end

% Get statistics of the offset calibration of sub-areas
function res = getSubStat(Lat, signal, x_range, y_range)
    s = partitionSignal4(signal, x_range, y_range);
    res.R_Sub = nan(length(s), 2);
    for i = 1:length(s)
        res.R_Sub(i, :) = Lat.convertFFTPhase2R(s(i).Signal, s(i).XRange, s(i).YRange);
    end
    res.R1_Mean = mean(res.R_Sub(:, 1));
    res.R1_Max = max(res.R_Sub(:, 1));
    res.R1_Min = min(res.R_Sub(:, 1));
    res.R1_Std = std(res.R_Sub(:, 1));
    res.R2_Mean = mean(res.R_Sub(:, 2));
    res.R2_Max = max(res.R_Sub(:, 2));
    res.R2_Min = min(res.R_Sub(:, 2));
    res.R2_Std = std(res.R_Sub(:, 2));
end

% Generate diagnostic plots on the FFT peak fits
function plotFFT(signal_fft, peak_init, peak_pos, all_peak_fit, ID)
    % Plot FFT magnitude in log scale
    figure("Name", "FFT Magnitude")
    Lattice.imagesc(log(signal_fft), "title", sprintf("[%s]: log(FFT)", ID))
    viscircles(peak_init(:, 2:-1:1), 7, "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
    viscircles(peak_pos(:, 2:-1:1), 2, "EnhanceVisibility", false, "Color", "red", "LineWidth", 1);
    num_peaks = size(peak_pos, 1);
    hold on
    for i = 1: num_peaks
        x = peak_pos(i, 2);
        y = peak_pos(i, 1);
        text(x + 10, y, num2str(i), "FontSize", 16, 'Color', 'r')
    end
    % Plot FFT peaks fits
    figure("Name", "FFT Peak fits", "Units", "normalized", "Position", [0.1, 0.1, 0.7, 0.7])
    sgtitle(ID)
    for i = 1:num_peaks
        subplot(1, num_peaks, i)
        [peak_fit, Corr, Z, ~] = all_peak_fit{i}{:};
        plot(peak_fit, Corr, Z)
        title(sprintf("Peak pos: (%g, %g)", peak_pos(i, :)))
    end
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
