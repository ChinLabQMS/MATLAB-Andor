function [small_box, x_range, y_range] = prepareBox(signal, center, r)
    arguments
        signal (:, :) double
        center (1, 2) double
        r (1, :) double
    end
    [x_size, y_size] = size(signal);
    xc = center(1);
    yc = center(2);
    rx = r(1);
    ry = r(end);
    
    x_range = floor(max(1, xc - rx)): ceil(min(x_size, xc + rx));
    y_range = floor(max(1, yc - ry)): ceil(min(y_size, yc + ry));

    small_box = signal(x_range,y_range);
end
