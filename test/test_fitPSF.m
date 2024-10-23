%% Loading the raw dataset
clear; clc;
% DataPath = 'data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat';
DataPath = 'calibration/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat';
Data = load(DataPath, "Data").Data;

%% Preprocess the data
Signal = Preprocessor().processData(Data);

%% Visualize a sample image

sample = Signal.Andor19330.Image(:, :, 1);

figure
Lattice.imagesc(sample)

%%
close all
psf = fitPSF(sample);

figure
Lattice.imagesc(psf)

%%
[fit_result, GOF, x, y, z] = fitGauss2D(psf);

function [average_psf, centroids] = fitPSF(image, thresh_percent, crop_size)
    arguments
        image (:, :, :) double
        thresh_percent (1, 1) double = 0.5
        crop_size (1,1) double = 10
    end

    % set a threshold
    threshold_value = thresh_percent*max(image(:));

    % label connected components
    labeled_image = image > threshold_value;
    % find centroids
    stats = regionprops(labeled_image, ["Centroid", "Area"]);
    centroids = cat(1, stats.Centroid);
    areas = cat(1, stats.Area);

    % Filter based on area
    area_thres = 25;
    idx = areas < area_thres;
    centroids = centroids(idx, :);
    
    % around each centroid, crop the image centered on the spot. then overlay them for PSF monitoring.
    
    % create 3D array to store cropped regions
    num_spots = size(centroids, 1);
    cropped_spots = zeros(2*crop_size+1, 2*crop_size+1, num_spots);
    
    % crop around each centroid and store in 3D array
    for i = 1:num_spots
        x = round(centroids(i, 1)); % x coord of centroid
        y = round(centroids(i, 2)); % y coord of centroid
        % define cropping window
        x_start = max(x-crop_size,1);
        x_end = min(x+crop_size,size(image,2));
        y_start = max(y-crop_size,1);
        y_end = min(y+crop_size,size(image,1));
        % crop image and store in array
        cropped_spot = image(y_start:y_end, x_start:x_end);
        cropped_spots(:,:,i) = cropped_spot;
    end
    
    % Display average psf
    average_psf = mean(cropped_spots,3);
end
