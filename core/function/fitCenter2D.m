function [XCenter, YCenter, XWidth, YWidth] = fitCenter2D(signal, options)
    arguments
        signal (:, :, :) double
        options.x_range = 1: size(signal, 1)
        options.y_range = 1: size(signal, 2)
    end    
    [y, x, z] = prepareSurfaceData(options.y_range, options.x_range, signal);
    z_sum = sum(z, "all");
    XCenter = sum(z .* x, "all") / z_sum;
    YCenter = sum(z .* y, "all") / z_sum;
    XWidth = sqrt(sum((x - XCenter).^2 .* z, "all") / z_sum);
    YWidth = sqrt(sum((y - YCenter).^2 .* z, "all") / z_sum);
end
