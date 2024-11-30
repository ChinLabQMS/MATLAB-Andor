function stats = findPeaks(img_data, options)
    arguments
        img_data
        options.binarize_threshold = 20
        options.filter_area_min = 5
        options.filter_intensity_min = 50
        options.filter_box_max = [15, 15]
        options.dbscan_distance = 10
        options.dbscan_single = true
        options.crop_radius = []
        options.filter_gauss_width = 3
        options.plot_diagnostic = true
    end
    props = ["WeightedCentroid", "Area", "BoundingBox", "MaxIntensity", "PixelIdxList"];
    if isempty(options.crop_radius)
        options.crop_radius = [1, 1] * options.dbscan_distance;
    end

    % Binarize image and find connected components
    img_bin = img_data > options.binarize_threshold;
    img_cc = bwconncomp(img_bin, 8);
    stats = regionprops("table", img_cc, img_data, props);

    % Filter the connected components by area to get rid of noise peaks
    stats0 = stats;
    stats = stats(stats.Area >= options.filter_area_min, :);

    % Use dbscan to find clusters of peaks
    stats1 = stats;
    labels = zeros(size(img_data));
    for i = 1: height(stats)
        labels(stats.PixelIdxList{i}) = i;
    end
    [Y, X] = meshgrid(1:size(labels, 2), 1:size(labels, 1));
    pix_x = X(labels > 0);
    pix_y = Y(labels > 0);
    clusters = dbscan([pix_x, pix_y], options.dbscan_distance, 1);
    labels(sub2ind(size(labels), pix_x, pix_y)) = clusters;
    for i = 1:height(stats)
        stats.Cluster(i) = mode(labels(stats.PixelIdxList{i}));
    end
    stats = convertvars(stats, 'Cluster', 'categorical');
    stats = join(stats, groupsummary(stats, "Cluster"));
    if options.dbscan_single
        % Only look at singly isolated peaks
        stats = stats(stats.GroupCount == 1, :);
    else
        % Merge peaks by cluster assignment to get a shorter stats
        stats = regionprops("table", labels, img_data, props);
    end

    % Filter again by intensity and bounding box size
    stats2 = stats;
    stats = stats(stats.MaxIntensity >= options.filter_intensity_min, :);
    stats3 = stats;
    stats = stats((stats.BoundingBox(:, 3) <= options.filter_box_max(2)) & ...
                  (stats.BoundingBox(:, 4) <= options.filter_box_max(1)), :);

    % Refine the centroids by fitting 2D Gaussian and filter by width
    stats4 = stats;
    if options.filter_gauss_width < inf
        for i = 1: height(stats)
            center = round(stats.WeightedCentroid(i, :));
            x_range = center(2) + (-options.crop_radius(1): options.crop_radius(1));
            y_range = center(1) + (-options.crop_radius(end): options.crop_radius(end));
            spot = img_data(x_range, y_range);
            [f, gof] = fitGauss2D(spot, x_range, y_range, 'cross_term', true);
            stats.RefinedCentroid(i, :) = [f.y0, f.x0];
            stats.RefinedWidth(i, :) = gof.eigen_widths;
            stats.RefinedAngle(i, :) = gof.eigen_angles;
            stats.MaxRefinedWidth(i) = max(gof.eigen_widths);
            stats.RefinedRSquare(i) = gof.rsquare;
        end
        stats = stats(stats.MaxRefinedWidth < options.filter_gauss_width, :);
    end
    
    if options.plot_diagnostic
        plotPeaks(img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats)
    end
end

function plotPeaks(img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats5)
    figure
    subplot(2, 3, 1)
    imagesc2(img_bin.*img_data, 'title', sprintf('0.Discretized: %d', size(stats0, 1)))
    viscircles(stats0.WeightedCentroid, sqrt(stats0.Area)/2);
    subplot(2, 3, 2)
    imagesc2(img_data, 'title', sprintf('1.After filtering small area: %d', size(stats1, 1)))
    viscircles(stats0.WeightedCentroid, sqrt(stats0.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats1.WeightedCentroid, sqrt(stats1.Area)/2);
    subplot(2, 3, 3)
    imagesc2(img_data, 'title', sprintf('2.After dbscan to find isolated: %d', size(stats2, 1)))
    viscircles(stats1.WeightedCentroid, sqrt(stats1.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats2.WeightedCentroid, sqrt(stats2.Area)/2);
    subplot(2, 3, 4)
    imagesc2(img_data, 'title', sprintf('3.After filter low-intensity: %d', size(stats3, 1)))
    viscircles(stats2.WeightedCentroid, sqrt(stats2.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2);
    subplot(2, 3, 5)
    imagesc2(img_data, 'title', sprintf('4.After filter bounding box size: %d', size(stats4, 1)))
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2);
    subplot(2, 3, 6)
    imagesc2(img_data, 'title', sprintf('5.After filtering gaussian fit width: %d', size(stats5, 1)))
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats5.RefinedCentroid, sqrt(stats5.Area)/2);
end
