classdef Lattice < BaseRunner
    
    properties (SetAccess = protected)
        K
        V
        R
    end

    properties (SetAccess = immutable)
        ID
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

        function init(Lat, K, V, R)
            Lat.K = K;
            Lat.V = V;
            Lat.R = R;
        end

        function calibrateR(Lat, signal, options)
            arguments
                Lat
                signal (:, :) double
                options.R_crop (1, :) double = Lat.Config.RFFT
                options.binarize_thres (1, 1) double = Lat.Config.CalibR_BinarizeThres
                options.outlier_thres (1, 1) double = Lat.Config.CalibR_OutlierThres
            end

            % Extract lattice center coordinates from phase at FFT peak
            [signal_box, x_range, y_range] = prepareBox(signal, Lat.R, options.R_crop);
            signal_modified = signal_box;
            signal_modified((signal_modified < options.binarize_thres) | (signal_modified > options.outlier_thres)) = 0;
        
            [Y, X] = meshgrid(y_range, x_range);
            phase_vec = zeros(1,2);
            for i = 1:2
                phase_mask = exp(-1i*2*pi*(Lat.K(i,1)*X + Lat.K(i,2)*Y));
                phase_vec(i) = angle(sum(phase_mask.*signal_modified,'all'));
            end
            Lat.R = (round(Lat.R*Lat.K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * Lat.V;
        end

        function calibrateV(Lat, signal, options)
            arguments
                Lat
                signal (:, :) double
                options.R_crop = Lat.Config.RFFT
                options.R_fit = Lat.Config.CalibV_RFit
                options.warning_latnorm_thres = Lat.Config.CalibV_WarnLatNormThres
                options.warning_rsquared = Lat.Config.CalibV_WarnRSquared
                options.plot_diagnostic (1, 1) logical = Lat.Config.CalibV_PlotDiagnostic
                options.plot_fftpeaks (1, 1) logical = Lat.Config.CalibV_PlotFFTPeaks 
            end
            LatInit = Lat.struct();

            [signal_box, x_range, y_range] = prepareBox(signal, Lat.R, options.R_crop);
            signal_fft = abs(fftshift(fft2(signal_box)));
            xy_size = size(signal_box);
            xy_center = (xy_size + 1) / 2;
            PeakPosInit = xy_size .* LatInit.K + xy_center;
            
            PeakPos = fitFFTPeaks(signal_fft, PeakPosInit, ...
                "R_fit", options.R_fit, "warning_rsquared", options.warning_rsquared, ...
                "plot_fftpeaks", options.plot_fftpeaks);
         
            Lat.K = (PeakPos - xy_center)./xy_size;
            Lat.V = (inv(Lat.K(1:2,:)))';
            Lat.calibrateR(signal, "R_crop", options.R_crop);
        
            VDis = vecnorm(Lat.V'-LatInit.V')./vecnorm(LatInit.V');
            if any(VDis > options.warning_latnorm_thres)
                warning('off','backtrace')
                warning('Lattice vector length changed significantly by %.2f%%.',...
                    100*(max(VDis)))
                warning('on','backtrace')
            end
        
            if options.plot_diagnostic
                figure
                Lat.plot(signal_box, "x_range", x_range, "y_range", y_range)
        
                figure
                imagesc(log(signal_fft))
                axis image
                hold on
                viscircles(PeakPosInit(:, 2:-1:1), 7, "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
                viscircles(PeakPos(:, 2:-1:1), 2, "EnhanceVisibility", false, "Color", "red", "LineWidth", 1);
            end
        end

        function plot(Lat, signal, options)
            arguments
                Lat
                signal (:, :) double
                options.ax = gca()
                options.x_range = 1:size(signal, 1)
                options.y_range = 1:size(signal, 2)
                options.latx_range = []
                options.laty_range = []
            end
            if isempty(options.latx_range) || isempty(options.laty_range)
                xmin = options.x_range(1);
                xmax = options.x_range(end);
                ymin = options.y_range(1);
                ymax = options.y_range(end);
                corners = [xmin, ymin; xmax, ymin; xmin, ymax; xmax, ymax];
                lat_corners = (corners - Lat.R)/Lat.V;
                lat_xmin = ceil(min(lat_corners(:, 1)));
                lat_xmax = floor(max(lat_corners(:, 1)));
                lat_ymin = ceil(min(lat_corners(:, 2)));
                lat_ymax = floor(max(lat_corners(:, 2)));
                [Y, X] = meshgrid(lat_ymin:lat_ymax, lat_xmin:lat_xmax);
                lat_corr = [X(:), Y(:)];
                corr = lat_corr * Lat.V + Lat.R;
                corr = corr((corr(:, 1) < xmax) & (corr(:, 1) > xmin) & (corr(:, 2) < ymax) & (corr(:, 2) > ymin), :);
            else
                [Y, X] = meshgrid(options.lat_yrange, options.lat_xrange);
                lat_corr = [X(:), Y(:)];
                corr = lat_corr * Lat.V + Lat.R;
            end
            
            imagesc(options.ax, options.y_range, options.x_range, signal)
            axis image
            colorbar
            hold on
            scatter(corr(:, 2), corr(:, 1), 2, 'filled', 'o','MarkerEdgeColor','none', 'MarkerFaceColor','red')
            hold off
        end

        function disp(Lat)
            V1 = Lat.V(1,:);
            V2 = Lat.V(2,:);
            V3 = V1+V2;
            fprintf('%s:\n', Lat.CurrentLabel)
            fprintf('\tV1=(%4.2f, %4.2f),\t|V1|=%4.2fpx\n',V1(1),V1(2),norm(V1))
            fprintf('\tV2=(%4.2f, %4.2f),\t|V2|=%4.2fpx\n',V2(1),V2(2),norm(V2))
            fprintf('\tV3=(%4.2f, %4.2f),\t|V3|=%4.2fpx\n',V3(1),V3(2),norm(V3))
            fprintf('\tAngle<V1,V2>=%4.2f deg\n',acosd(V1*V2'/(norm(V1)*norm(V2))))
            fprintf('\tAngle<V1,V3>=%4.2f deg\n',acosd(V1*V3'/(norm(V1)*norm(V3))))
        end

        function label = getStatusLabel(Lat)
            if Lat.ID ~= ""
                label = sprintf(" (%s)", Lat.ID);
            else
                label = "";
            end
        end
    end
end

function [PeakPos, FFTPeakFit] = fitFFTPeaks(FFT, PeakPosInit, options)
    arguments
        FFT (:, :) double
        PeakPosInit (:, 2) double
        options.R_fit (1, 1) double
        options.method (1, 1) string = "Gauss2DLinear"
        options.warning_rsquared (1, 1) double = 0.5
        options.plot_fftpeaks (1, 1) logical = false
    end
    PeakPos = PeakPosInit;
    num_peaks = size(PeakPosInit, 1);
    FFTPeakFit = cell(1, num_peaks);
    rx = options.R_fit(1);
    ry = options.R_fit(end);
    
    for i = 1:num_peaks
        center = round(PeakPosInit(i, :));
        [peak_data, x_range, y_range] = prepareBox(FFT, center, [rx, ry]);
        
        % Fitting FFT peaks
        if options.method == "Gauss2DLinear"
            [PeakFit,GOF,X,Y,Z] = fitGauss2D(peak_data, ...
                "x_range", -rx:rx, "y_range", -ry:ry, "offset", "linear");
            FFTPeakFit{i} = {PeakFit,[X,Y],Z,GOF};
            if GOF.rsquare < options.warning_rsquared
                PeakPos = PeakPosInit;
                warning('off','backtrace')
                warning('FFT peak fit might be off (rsquare=%.3f), not updating calibration.',...
                    GOF.rsquare)
                warning('on','backtrace')
                return
            else
                PeakPos(i, :) = [PeakFit.x0, PeakFit.y0] + center;
            end
        elseif options.method == "Max"
            [Y, X] = meshgrid(y_range, x_range);
            [max_val, max_idx] = max(peak_data, [], "all");
            FFTPeakFit{i} = max_val;
            PeakPos(i, :) = [X(max_idx), Y(max_idx)];
        end
    end
    if options.plot_fftpeaks && options.method == "Gauss2DLinear"
        figure
        for i = 1:num_peaks
            subplot(1, num_peaks, i)
            [PeakFit, Corr, Z, ~] = FFTPeakFit{i}{:};
            plot(PeakFit, Corr, Z)
        end
    end
end
