a = magic(4);
s = partitionSignal(a);
disp(s)

function s = partitionSignal(signal, x_range, y_range)
    arguments
        signal (:, :) double
        x_range (1, :) double = 1:size(signal, 1)
        y_range (1, :) double = 1:size(signal, 2)
    end
    x_idx1 = 1:floor(length(x_range) / 2);
    x_idx2 = floor(length(x_range) / 2) + 1: length(x_range);
    y_idx1 = 1:floor(length(y_range) / 2);
    y_idx2 = floor(length(y_range) / 2) + 1: length(y_range);
    x_idx = [x_idx1; x_idx1; x_idx2; x_idx2];
    y_idx = [y_idx1; y_idx2; y_idx1; y_idx2];
    x_range_list = x_range(x_idx);
    y_range_list = y_range(y_idx);
    s(4) = struct();
    for i = 1:4
        s(i).XRange = x_range_list(i, :);
        s(i).YRange = y_range_list(i, :);
        s(i).Signal = signal(x_idx(i, :), y_idx(i, :));
    end
end
