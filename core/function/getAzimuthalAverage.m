function [val, r_range] = getAzimuthalAverage(signal, center, x_range, y_range, options)
    arguments
        signal
        center = [1, 1]
        x_range {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
        y_range {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
        options.bin_radial = 1
    end
    [Y, X] = meshgrid(y_range - center(2), x_range - center(1));
    L = round(sqrt(X.^2 + Y.^2) / options.bin_radial) + 1;
    r_idx = unique(L(:));
    r_range = r_idx  * options.bin_radial;
    sum_intensities = accumarray(L(:), signal(:));
    pixel_counts = accumarray(L(:), 1);
    val = sum_intensities ./ pixel_counts;
    val = val(r_idx);
end
