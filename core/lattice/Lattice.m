 classdef Lattice < BaseObject
    %LATTICE Class for lattice calibration and conversion
    
    properties (SetAccess = protected)
        K  % Momentum-space reciprocal vectors, 2x2 double
        V  % Real-space lattice vectors, 2x2 double
        R  % Real-space lattice center, 1x2 double
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
                center (1, 2) double
                xy_size = []
                peak_pos = []
            end
            if ~isempty(peak_pos) && ~isempty(xy_size)
                [Lat.K, Lat.V] = convertFFTPeak2K(xy_size, peak_pos);
            end
            Lat.R = center;
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
        % TODO: Bootstrapping to 4 equal parts to get uncertainty
        function calibrateR(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double = 1:size(signal, 1)
                y_range (1, :) double = 1:size(signal, 2)
                options.label (1, :) string = "Image"
                options.binarize_thres (1, 1) double = LatCalibConfig.CalibR_BinarizeThres
                options.plot_diagnostic (1, 1) logical = LatCalibConfig.CalibR_PlotDiagnostic
            end
            signal_modified = signal;
            % If the image is not directly from lattice, do filtering
            if options.label ~= "Lattice"
                thres = options.binarize_thres * max(signal(:));
                signal_modified((signal_modified < thres)) = 0;
            end

            % Extract lattice center coordinates from phase at FFT peak
            [Y, X] = meshgrid(y_range, x_range);
            phase_vec = zeros(1,2);
            for i = 1:2
                phase_mask = exp(-1i*2*pi*(Lat.K(i,1)*X + Lat.K(i,2)*Y));
                phase_vec(i) = angle(sum(phase_mask.*signal_modified, 'all'));
            end
            Lat.R = (round(Lat.R*Lat.K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * Lat.V;
            if options.plot_diagnostic
                figure
                Lat.imageSignal(signal_modified, x_range, y_range, "title", sprintf("%s: Signal (modified)", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV("origin", Lat.R)
            end
        end
        
        % Calibrate lattice vectors with FFT
        function varargout = calibrateV(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double = 1:size(signal, 1)
                y_range (1, :) double = 1:size(signal, 2)
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
            [peak_pos, all_peak_fit] = Lat.fitFFTPeaks(signal_fft, peak_init, ...
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
                Lat.imageSignal(signal, x_range, y_range, "title", sprintf("%s: Signal (modified)", Lat.ID))
                Lat.plot([], 'full_range', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
                Lat.plotV("origin", Lat.R)
            end
        end

        % Convert coordinates in Lat camera space to Lat2 camera space
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
                x_range (1, :) double = 1: size(signal, 1)
                y_range (1, :) double = 1: size(signal, 2)
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
            transformed2(idx) = signal(corr(idx, 1) - options.x_lim(1) + 1 ...
                + (corr(idx, 2) - options.y_lim(1)) * size(signal, 1));
        end
        
        % Calibrate the origin of Lat to Lat2 based on signal overlapping
        function varargout = calibrateO(Lat, Lat2, signal, x_range, y_range, ...
                signal2, x_range2, y_range2, options)
            arguments
                Lat (1, 1) Lattice
                Lat2 (1, 1) Lattice
                signal (:, :) double
                x_range (1, :) double
                y_range (1, :) double
                signal2 (:, :) double
                x_range2 (1, :) double
                y_range2 (1, :) double
                options.sites = LatCalibConfig.CalibO_Sites
                options.verbose (1, 1) logical = LatCalibConfig.CalibO_Verbose
                options.plot_diagnostic (1, 1) logical = LatCalibConfig.CalibO_PlotDiagnostic
            end
            best_transformed = [];
            best_center = [];
            best_score = 0;
            for site = options.sites'
                Lat.init(site');
                transformed = Lat2.transformSignal(Lat, x_range, y_range, signal2, x_range2, y_range2);
                score = 1 - pdist2(signal(:)', transformed(:)', "cosine");
                if score > best_score
                    best_transformed = transformed;
                    best_center = site';
                    best_score = score;
                end
                if options.verbose
                    obj.info("Trying site (%d, %d), score is %4.2f.", site(1), site(2), score)
                end
            end
            if isempty(best_score)
                obj.error("Cross calibration failed, no score above 0 found.")
            end
            Lat.init(best_center);
            obj.info("Lattice center is cross-calibrated. Maximum cosine similarity is %4.2f.", max_v)
            if nargout == 1
                varargout{1} = best_transformed;
            end
            if options.plot_diagnostic
                figure
                subplot(1, 3, 1)
                Lat.imageSignal(signal, x_range, y_range, "title", sprintf("%s: calibrated", Lat.ID))
                Lat.plot(options.sites)
                subplot(1, 3, 2)
                Lat2.imageSignal(signal, x_range, y_range, "title", sprintf("%s: original", Lat2.ID))
                Lat2.plot(options.sites)
                subplot(1, 3, 3)
                Lat.imageSignal(best_transformed, x_range, y_range, "title", sprintf("%s: best_transformed from %s", Lat.ID, Lat2.ID))
                Lat.plot(options.sites)
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
            % Create a group of lines of circles
            h = viscircles(options.ax, corr(:, 2:-1:1), radius, ...
                'Color', options.color, 'EnhanceVisibility', false, 'LineWidth', options.line_width);
            % Output the handle to the group
            if nargout == 1
                varargout{1} = h;
            end
        end
        
        % Plot lattice vectors
        function plotV(Lat, options)
            arguments
                Lat
                options.ax = gca()
                options.origin (1, 2) double = [0, 0]
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

        % Display lattice calibration details
        function disp(Lat)
            v1 = Lat.V1;
            v2 = Lat.V2;
            v3 = Lat.V3;
            fprintf('%s%s: \n\tR = (%5.2f, %5.2f)\n', class(Lat), Lat.getStatusLabel(), Lat.R(1), Lat.R(2))
            fprintf('\tV1 = (%5.2f, %5.2f),\t|V1| = %5.2f px\n', v1(1), v1(2), norm(v1))
            fprintf('\tV2 = (%5.2f, %5.2f),\t|V2| = %5.2f px\n', v2(1), v2(2), norm(v2))
            fprintf('\tV3 = (%5.2f, %5.2f),\t|V3| = %5.2f px\n', v3(1), v3(2), norm(v3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(v1*v2'/(norm(v1)*norm(v2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n', acosd(v1*v3'/(norm(v1)*norm(v3))))
        end
        
        function val = get.V1(Lat)
            val = Lat.V(1,:);
        end

        function val = get.V2(Lat)
            val = Lat.V(2,:);
        end

        function val = get.V3(Lat)
            v1 = Lat.V1;
            v2 = Lat.V2;
            if acosd(v1*v2'/(norm(v1)*norm(v2))) > 90
                val = v1 + v2;
            else
                val = v1 - v2;
            end
        end
    end
    
    methods (Access = protected)
        function label = getStatusLabel(Lat)
            label = sprintf(" (%s)", Lat.ID);
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
    end

    methods (Static)
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

        function imageSignal(signal, x_range, y_range, ax, options)
            arguments
                signal (:, :) double
                x_range (1, :) double = 1: size(signal, 1)
                y_range (1, :) double = 1: size(signal, 2)
                ax = gca()
                options.title (1, 1) string = ""
            end
            imagesc(ax, y_range, x_range, signal)
            axis image
            colorbar
            title(options.title)
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

% Generate diagnostic plots on the FFT peak fits
function plotFFT(signal_fft, peak_init, peak_pos, all_peak_fit, ID)
    % Plot FFT magnitude in log scale
    figure("Name", "FFT Magnitude")
    Lattice.imageSignal(log(signal_fft), "title", sprintf("[%s]: log(FFT)", ID))
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

function mustBeValidRange(obj, signal, dim, range)
    if size(signal, dim) ~= length(range)
        obj.error("Range does not match signal dimension.")
    end
end
