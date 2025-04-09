function [signal_sum, x_range, y_range] = getSignalSum(signal, num_frames, options)
arguments
    signal 
    num_frames 
    options.first_only = false
end
    signal = mean(signal, 3);
    [x_size, y_size] = size(signal, [1, 2]);
    x_frame = x_size / num_frames;
    x_range = 1: x_frame;
    y_range = 1: y_size;
    if options.first_only
        signal_sum = signal(x_range, y_range);
    else
        signal_sum = zeros(x_frame, y_size);
        for i = 1:num_frames
            signal_sum = signal_sum + signal((i-1)*x_frame + (1:x_frame), 1:y_size);
        end
    end
end
