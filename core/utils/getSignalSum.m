function [signal_sum, x_frame, y_size] = getSignalSum(signal, num_frames)
    signal = mean(signal, 3);
    [x_size, y_size] = size(signal, [1, 2]);
    x_frame = x_size / num_frames;
    signal_sum = zeros(x_frame, y_size);
    for i = 1:num_frames
        signal_sum = signal_sum + signal((i-1)*x_frame + (1:x_frame), 1:y_size);
    end
end
