classdef Lattice < BaseRunner
    
    properties (SetAccess = protected)
        K
        V
        R
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
        function Lat = Lattice(ID, config)
            arguments
                ID (1, 1) string = "Test"
                config (1, 1) LatticeConfig = LatticeConfig()
            end
            Lat@BaseRunner(config)
            Lat.ID = ID;            
        end

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

        function [corr, lat_corr] = convert(Lat, lat_corr, x_lim, y_lim)
            arguments
                Lat
                lat_corr
                x_lim = [1, 1024]
                y_lim = [1, 1024]
            end
            corr = lat_corr * Lat.V + Lat.R;
            idx = (corr(:, 1) >= x_lim(1)) & (corr(:, 1) <= x_lim(2) & (corr(:, 2) >= y_lim(1)) & (corr(:, 2) <= y_lim(2)));
            corr = corr(idx, :);
            lat_corr = lat_corr(idx, :);
        end

        function calibrateR(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double = 1:size(signal, 1)
                y_range (1, :) double = 1:size(signal, 2)
                options.binarize_thres (1, 1) double = Lat.Config.CalibR_BinarizeThres
                options.outlier_thres (1, 1) double = Lat.Config.CalibR_OutlierThres
            end            
            signal_modified = signal;
            signal_modified((signal_modified < options.binarize_thres) | (signal_modified > options.outlier_thres)) = 0;        
            % Extract lattice center coordinates from phase at FFT peak
            [Y, X] = meshgrid(y_range, x_range);
            phase_vec = zeros(1,2);
            for i = 1:2
                phase_mask = exp(-1i*2*pi*(Lat.K(i,1)*X + Lat.K(i,2)*Y));
                phase_vec(i) = angle(sum(phase_mask.*signal_modified, 'all'));
            end
            Lat.R = (round(Lat.R*Lat.K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * Lat.V;
        end

        function vargout = calibrateV(Lat, signal, x_range, y_range, options)
            arguments
                Lat
                signal (:, :) double
                x_range (1, :) double = 1:size(signal, 1)
                y_range (1, :) double = 1:size(signal, 2)
                options.R_fit = Lat.Config.CalibV_RFit
                options.warning_latnorm_thres = Lat.Config.CalibV_WarnLatNormThres
                options.warning_rsquared = Lat.Config.CalibV_WarnRSquared
                options.plot_diagnostic (1, 1) logical = Lat.Config.CalibV_PlotDiagnostic
            end
            LatInit = Lat.struct();
            signal_fft = abs(fftshift(fft2(signal)));
            xy_size = size(signal);
            peak_init = convertK2FFTPeak(xy_size, Lat.K);
            [peak_pos, all_peak_fit] = fitFFTPeaks(signal_fft, peak_init, ...
                "R_fit", options.R_fit, "warning_rsquared", options.warning_rsquared);         
            [Lat.K, Lat.V] = convertFFTPeak2K(xy_size, peak_pos);
            Lat.calibrateR(signal, x_range, y_range)
            if nargout == 1
                vargout{1} = peak_pos;
            end
        
            VDis = vecnorm(Lat.V'-LatInit.V')./vecnorm(LatInit.V');
            if any(VDis > options.warning_latnorm_thres)
                warning('off','backtrace')
                warning('Lattice vector length changed significantly by %.2f%%.',...
                    100*(max(VDis)))
                warning('on','backtrace')
            end
            if options.plot_diagnostic
                plotFFT(signal_fft, peak_init, peak_pos, all_peak_fit, Lat.ID)
                Lat.plot(signal, x_range, y_range)
            end
        end

        function plot(Lat, signal, x_range, y_range)
            arguments
                Lat
                signal (:, :) double
                x_range = 1:size(signal, 1)
                y_range = 1:size(signal, 2)
            end
            xmin = x_range(1);
            xmax = x_range(end);
            ymin = y_range(1);
            ymax = y_range(end);
            corners = [xmin, ymin; xmax, ymin; xmin, ymax; xmax, ymax];
            lat_corners = (corners - Lat.R)/Lat.V;
            lat_xmin = ceil(min(lat_corners(:, 1)));
            lat_xmax = floor(max(lat_corners(:, 1)));
            lat_ymin = ceil(min(lat_corners(:, 2)));
            lat_ymax = floor(max(lat_corners(:, 2)));
            [Y, X] = meshgrid(lat_ymin:lat_ymax, lat_xmin:lat_xmax);
            corr = Lat.convert([X(:), Y(:)], [x_range(1), x_range(end)], [y_range(1), y_range(end)]);
            
            figure
            imagesc(y_range, x_range, signal)
            axis image
            colorbar
            hold on
            radius = 0.1 * norm(Lat.V1);
            viscircles(corr(:, 2:-1:1), radius, 'EnhanceVisibility', false, 'LineWidth', 0.5);
            title(sprintf("%s: Signal", Lat.ID))
            hold off
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

        function disp(Lat)
            v1 = Lat.V1;
            v2 = Lat.V2;
            v3 = Lat.V3;
            fprintf('%s: \n\tR = (%5.2f, %5.2f)\n', Lat.CurrentLabel, Lat.R(1), Lat.R(2))
            fprintf('\tV1 = (%5.2f, %5.2f),\t|V1| = %5.2f px\n', v1(1), v1(2), norm(v1))
            fprintf('\tV2 = (%5.2f, %5.2f),\t|V2| = %5.2f px\n', v2(1), v2(2), norm(v2))
            fprintf('\tV3 = (%5.2f, %5.2f),\t|V3| = %5.2f px\n', v3(1), v3(2), norm(v3))
            fprintf('\tAngle<V1,V2> = %6.2f deg\n', acosd(v1*v2'/(norm(v1)*norm(v2))))
            fprintf('\tAngle<V1,V3> = %6.2f deg\n', acosd(v1*v3'/(norm(v1)*norm(v3))))
        end

        function label = getStatusLabel(Lat)
            label = sprintf(" (%s)", Lat.ID);
        end
    end
end

function [K, V] = convertFFTPeak2K(xy_size, peak_pos)
    xy_center = floor(xy_size / 2) + 1;
    K = (peak_pos - xy_center)./xy_size;
    V = (inv(K(1:2,:)))';
end

function peak_pos = convertK2FFTPeak(xy_size, K)
    xy_center = floor(xy_size / 2) + 1;
    peak_pos = K.*xy_size + xy_center;
end

function [peak_pos, all_peak_fit] = fitFFTPeaks(FFT, peak_init, options)
    arguments
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
            peak_pos = peak_init;
            warning('off','backtrace')
            warning('FFT peak fit might be off (rsquare=%.3f), not updating calibration.',...
                GOF.rsquare)
            warning('on','backtrace')
            return
        else
            peak_pos(i, :) = [PeakFit.x0, PeakFit.y0] + center;
        end
    end
end

function plotFFT(signal_fft, peak_init, peak_pos, all_peak_fit, ID)
    % Plot FFT magnitude in log scale
    figure("Name", "FFT Magnitude")
    imagesc(log(signal_fft))
    title(sprintf("[%s]: log(FFT)", ID))
    axis image
    colorbar
    hold on
    viscircles(peak_init(:, 2:-1:1), 7, "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
    viscircles(peak_pos(:, 2:-1:1), 2, "EnhanceVisibility", false, "Color", "red", "LineWidth", 1);
    num_peaks = size(peak_pos, 1);

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
