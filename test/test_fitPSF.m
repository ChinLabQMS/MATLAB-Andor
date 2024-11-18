%% Loading the raw dataset
clear; clc;
% DataPath = 'data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat';
% DataPath = 'calibration/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat';
DataPath = "data/2024/11 November/20241111/Warmup_sparse2.mat";
% DataPath = "data/2024/11 November/20241115 projecting gray/gray_cross_on_black_angled_angle=-17.1_width=5_row=0.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);

%% Visualize a sample image

sample = Signal.Andor19330.Image(:, :, 1);

figure
imagesc2(sample)

%%
close all
stats = fitPSF(sample);

function [stats] = fitPSF(img_data, x_range, y_range, options)
    arguments
        img_data
        x_range = 1: size(img_data, 1)
        y_range = 1: size(img_data, 2)
        options.thres_max_k = 5
        options.thresh_pct_signal = 0.5
        options.thresh_min = 40
        options.thresh_max = 40;
        options.filter_on_distance = true
        options.filter_distance_min = 13
        options.filter_distance_max = Inf
        options.filter_on_box = false
        options.filter_box_xmin = 1
        options.filter_box_ymin = 1
        options.filter_box_xmax = 6
        options.filter_box_ymax = 6
        options.crop_radius = 10
        options.scale = 10
        options.plot_diagnostic = true
    end
    k_vals = maxk(img_data(:), options.thres_max_k);
    threshold = max(options.thresh_min, min(options.thresh_max, options.thresh_pct_signal*k_vals(end)));
    stats = regionprops("table", img_data > threshold, img_data, ...
        ["Area", "BoundingBox", "WeightedCentroid"]);
    if options.filter_on_distance
        idx = true(size(stats, 1), 1);
        d = squareform(pdist(stats.WeightedCentroid));
        d(1:size(d, 1) + 1:end) = nan;
        idx = idx & (min(d)' > options.filter_distance_min) ...
                  & (max(d)' < options.filter_distance_max);
        stats = stats(idx, :);
    end
    if options.filter_on_box
        idx = true(size(stats, 1), 1);
        idx = idx & (stats.BoundingBox(:, 4) > options.filter_box_xmin)  ...
                  & (stats.BoundingBox(:, 4) < options.filter_box_xmax) ...
                  & (stats.BoundingBox(:, 3) > options.filter_box_ymin) ...
                  & (stats.BoundingBox(:, 3) < options.filter_box_ymax);
        stats = stats(idx, :);
    end
    num_spot = size(stats, 1);
    if num_spot == 0
        
    end
    if options.plot_diagnostic
        figure
        imagesc2(y_range, x_range, img_data)
        viscircles(stats.WeightedCentroid, 5);
    end
    spot_size = options.scale * (2*options.crop_radius + 1);
    spots = zeros(spot_size(1), spot_size(end), num_spot);
    for i = 1: num_spot
        x_center = round(stats.WeightedCentroid(i, 1));
        y_center = round(stats.WeightedCentroid(i, 2));
    end
end
