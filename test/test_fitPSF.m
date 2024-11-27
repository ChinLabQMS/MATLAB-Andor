%% Loading the raw dataset
clear; clc;
% DataPath = 'data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat';
% DataPath = 'calibration/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat';
DataPath = "data/2024/11 November/20241111/Warmup_sparse2.mat";
% DataPath = "data/2024/11 November/20241115 projecting gray/gray_cross_on_black_angled_angle=-17.1_width=5_row=0.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);

%% Visualize a sample image

sample = Signal.Andor19330.Image(:, :, 3);
p = PointFitter();
stats = findPeaks(p, sample, 'plot_diagnostic', 1, 'verbose', 1);

%%


%%
expected = @(x, y) exp(-1/2*(x./options.target_sigma).^2 - 1/2*(y./options.target_sigma).^2);
padding = ones(2*options.crop_radius(1) + 1, 2*options.crop_radius(end) + 1);
[Y, X] = meshgrid((-options.crop_radius(end): options.crop_radius(end)), ...
                  (-options.crop_radius(1) : options.crop_radius(1)));
idx = (X(:).^2 + Y(:).^2) < (2*options.target_sigma)^2;
padding(idx) = 0;
h = imagesc2(padding);

kernel = reshape(expected(X(:), Y(:)), 2*options.crop_radius(1)+1, 2*options.crop_radius(end)+1);
h = imagesc2(kernel);

%%
for i = 1: size(stats, 1)
% for i = 6
    center = stats.WeightedCentroid(i, 2:-1:1);
    crop_x = round(center(1)) + (-options.crop_radius(1) : options.crop_radius(1));
    crop_y = round(center(2)) + (-options.crop_radius(end): options.crop_radius(end));
    [Y, X] = meshgrid(crop_y, crop_x);
    
    idx = sub2ind(size(img_data), X(:), Y(:));
    Z = reshape(img_data(idx), length(crop_x), length(crop_y));
    target = reshape(expected(X(:) - center(1), Y(:) - center(2)), length(crop_x), length(crop_y));
    stats.TargetDist(i) = pdist2(Z(:)', target(:)', 'Cosine');
    stats.MSE(i) = sqrt(mean((Z.*padding).^2, 'all'));
    stats.MSE2(i) = sqrt(mean((stats.MaxIntensity(i)*kernel - Z).^2 ./ (32 + Z), 'all'));
    % disp(stats(i, :))

    subplot(3, 1, 1)
    imagesc2(Z)
    title(stats.Cluster(i))
    subplot(3, 1, 2)
    imagesc2(reshape(img_bin(idx), length(crop_x), length(crop_y)))
    subplot(3, 1, 3)
    delete(h)
    hold on
    h = scatter(stats.MSE2(i), stats.TargetDist(i), 'r');
end

%%
hold off
scatter3(stats.MSE2, stats.TargetDist, stats.MaxIntensity)
xlabel('MSE2')
ylabel('Dist')
zlabel('MaxInt')

%%
stats((stats.MSE2 > 2.5), :)


function stats = findPeaks(obj, img_data, expected_sigma, options)
    arguments
        obj
        img_data
        expected_sigma = obj.FindPeak_ExpectedSigma
        options.plot_diagnostic = obj.FindPeak_PlotDiagnostic
        options.verbose = obj.FindPeak_Verbose
        options.peak_properties = ["WeightedCentroid", "BoundingBox", "MaxIntensity", "Area"]
        options.binarize_threshold = 30
        options.filter_area_min = obj.FindPeak_FilterAreaMin
        options.filter_intensity_min = obj.FindPeak_FilterIntensityMin
        options.dbscan_distance = obj.FindPeak_DBScanDistSigma * expected_sigma
        options.dbscan_single_only = obj.FindPeak_DBScanSingleOnly
        options.filter_box_xmax = obj.FindPeak_FilterBoxXMaxSigma * expected_sigma
        options.filter_box_ymax = obj.FindPeak_FilterBoxYMaxSigma * expected_sigma
    end
    timer = tic;
    % Binarize image and find connected components
    img_bin = img_data > options.binarize_threshold;
    stats = regionprops("table", img_bin, img_data, options.peak_properties);
    % Filter the connected components by area and intensity
    stats = stats(stats.Area >= options.filter_area_min, :);
    stats = stats(stats.MaxIntensity >= options.filter_intensity_min, :);
    % Use dbscan to cluster nearby peaks
    stats.Cluster = dbscan(stats.WeightedCentroid, options.dbscan_distance, 1);
    stats = convertvars(stats, 'Cluster', 'categorical');
    stats = renamevars(groupsummary(stats, 'Cluster', 'mean', options.peak_properties), ...
        arrayfun(@(x) "mean_" + x, options.peak_properties), options.peak_properties);
    if options.dbscan_single_only
        stats = stats((stats.GroupCount == 1), :);
    end
    % Filter on bounding box size
    stats = stats(...
        (stats.BoundingBox(:, 4) <= options.filter_box_xmax) & ...
        (stats.BoundingBox(:, 3) <= options.filter_box_ymax), :);
    centroids = stats.WeightedCentroid;
    if options.plot_diagnostic
        figure
        imagesc2(img_data)
        viscircles(stats.WeightedCentroid, 3*expected_sigma);
    end
    if options.verbose
        obj.info('Find %d peaks in the image, elapsed time is %g s.', size(centroids, 1), toc(timer))
    end
end