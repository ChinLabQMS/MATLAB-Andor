function [val, r_val] = getAzimuthalAverage(signal, center, x_range, y_range, options)
    arguments
        signal
        center = [1, 1]
        x_range {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
        y_range {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
        options.bin_radial = 1
        options.half_range = false
    end
    [Y, X] = meshgrid(y_range - center(2), x_range - center(1));
    L = sqrt(X.^2 + Y.^2);
    if options.half_range
        L = L.*sign(X);
    end
    r_range = floor(min(L(:))):options.bin_radial:ceil(max(L(:)));
    r_val = (r_range(1:end-1) + r_range(2:end))/2;
    r_group = discretize(L, r_range);
    sum_intensities = accumarray(reshape(r_group, [], 1), reshape(signal, [], 1), ...
                                [length(r_val), 1], @sum, 0);
    pixel_counts   = accumarray(reshape(r_group, [], 1), 1, ...
                                [length(r_val), 1], @sum, 0);
    val = sum_intensities ./ max(pixel_counts, 1);
end
