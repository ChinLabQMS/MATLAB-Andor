function [XCenter, YCenter, XWidth, YWidth] = fitCenter2D(signal, x_range, y_range)
    arguments
        signal (:, :, :) double
        x_range = 1: size(signal, 1)
        y_range = 1: size(signal, 2)
    end    
    [y, x, z] = prepareSurfaceData(y_range, x_range, signal);
    z_sum = sum(z, "all");
    XCenter = sum(z .* x, "all") / z_sum;
    YCenter = sum(z .* y, "all") / z_sum;
    XWidth = real(sqrt(sum((x - XCenter).^2 .* z, "all") / z_sum));
    YWidth = real(sqrt(sum((y - YCenter).^2 .* z, "all") / z_sum));
end
