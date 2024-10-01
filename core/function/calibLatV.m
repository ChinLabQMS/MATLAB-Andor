function [Lat, PeakPos, FFTPeakFit] = calibLatV(signal, LatInit, options)
    arguments
        signal (:, :) double
        LatInit (1, 1) struct
        options.R_crop = 100
        options.R_fit = 7
        options.warning_thres = 0.01
    end

    signal_box = prepareBox(signal, LatInit.R, options.R_crop);
    xy_size = size(signal_box);
    xy_center = (xy_size + 1) / 2;
    PeakPosInit = xy_size .* LatInit.K + xy_center;
    
    FFT = abs(fftshift(fft2(signal_box)));
    [PeakPos, FFTPeakFit] = fitFFTPeaks(FFT, PeakPosInit, options.R_fit);
 
    Lat.K = (PeakPos - xy_center)./xy_size;
    Lat.V = (inv(Lat.K(1:2,:)))';
    Lat.R = LatInit.R;

    VDis = vecnorm(Lat.V'-LatInit.V')./vecnorm(LatInit.V');
    if any(VDis > options.warning_thres)
        warning('off','backtrace')
        warning('Lattice vector length changed significantly by %.2f%%.',...
            100*(max(VDis)))
        warning('on','backtrace')
    end
end

function [PeakPos, FFTPeakFit] = fitFFTPeaks(FFT, PeakPosInit, R_fit)
    PeakPos = PeakPosInit;
    num_peaks = size(PeakPosInit, 1);
    FFTPeakFit = cell(1, num_peaks);
    rx = R_fit(1);
    ry = R_fit(end);
    
    for i = 1:num_peaks
        xc = round(PeakPosInit(i,1));
        yc = round(PeakPosInit(i,2));
        x_range = xc + (-rx:rx);
        y_range = yc + (-ry:ry);
        PeakData = FFT(x_range, y_range);
        
        % Fitting FFT peaks
        [PeakFit,GOF,X,Y,Z] = fitGauss2D(PeakData,"x_range", -rx:rx, "y_range", -ry:ry);
        FFTPeakFit{i} = {PeakFit,[X,Y],Z,GOF};

        if GOF.rsquare < 0.5
            PeakPos = PeakPosInit;
            warning('off','backtrace')
            warning('FFT peak fit might be off (rsquare=%.3f), not updating.',...
                GOF.rsquare)
            warning('on','backtrace')
            return
        else
            PeakPos(i,:) = [PeakFit.x0, PeakFit.y0] + [xc,yc];
        end
    end
end
