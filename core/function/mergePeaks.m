function [psf, x_range, y_range, peaks] = mergePeaks(img_data, centroids, options)
    arguments
        img_data
        centroids
        options.scale = 10
        options.crop_radius = [10, 10]
        options.plot_diagnostic = true
    end
    peaks = repmat(zeros(options.scale * (2*options.crop_radius + 1)), ...
                   1, 1, size(centroids, 1));
    x_size = options.scale * (2*options.crop_radius(1) + 1);
    y_size = options.scale * (2*options.crop_radius(end) + 1);
    x_range = ((1: x_size) - (1 + x_size)/2)./options.scale;
    y_range = ((1: y_size) - (1 + y_size)/2)./options.scale;
    for i = 1: height(centroids)
        center = centroids(i, :);
        sample_x = round(center(2)) + (-options.crop_radius(1): options.crop_radius(1));
        sample_y = round(center(1)) + (-options.crop_radius(end): options.crop_radius(end));
        sample = kron(img_data(sample_x, sample_y), ones(options.scale));
        x_shift = round(options.scale * (round(center(2)) - center(2)));
        y_shift = round(options.scale * (round(center(1)) - center(1)));
        sample = circshift(sample, x_shift, 1);
        sample = circshift(sample, y_shift, 2);
        peaks(:, :, i) = sample;
    end
    psf = mean(peaks, 3);
    if options.plot_diagnostic
        figure
        imagesc2(y_range, x_range, psf)
    end
end
