function [xc, yc, xw, yw] = fitCenter2D(signal, x_range, y_range)
    arguments
        signal (:, :, :) double
        x_range = 1: size(signal, 1)
        y_range = 1: size(signal, 2)
    end    
    [y, x, z] = prepareSurfaceData(y_range, x_range, signal);
    z_sum = sum(z, "all");
    xc = sum(z .* x, "all") / z_sum;
    yc = sum(z .* y, "all") / z_sum;
    xw = real(sqrt(sum((x - xc).^2 .* z, "all") / z_sum));
    yw = real(sqrt(sum((y - yc).^2 .* z, "all") / z_sum));
end
