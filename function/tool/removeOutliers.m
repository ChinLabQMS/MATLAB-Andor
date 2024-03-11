function new_images = removeOutliers(images, threshold)
    arguments
        images
        threshold (1, 1) double = 15
    end
    images = double(images);

    median_image = median(images, 3);
    median_dev = median(abs(images-median_image), 'all');
    norm_median_dev = abs(images-median_image)/median_dev;

    new_images = images;
    outliers = norm_median_dev > threshold;
    new_images(outliers) = nan;

    num_outliers = sum(outliers, 'all');
    num_elements = numel(new_images);
    fprintf('Number of pixels disposed: %d, percentage in data: %.6f%%\n', num_outliers, num_outliers/num_elements*100)
end