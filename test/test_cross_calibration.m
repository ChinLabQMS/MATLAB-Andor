%% Load Dataset and calibration
clear; clc

Data = load('data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat', 'Data').Data;
LatCalib = load("calibration/LatCalib_20241002.mat");

Lat19330 = LatCalib.Andor19330;
Lat19331 = LatCalib.Andor19331;

%% Preprocess
Signal = Preprocessor().processData(Data);

%% Pick a single image
signal2 = Signal.Andor19330.Image(:, :, 1);
signal = Signal.Andor19331.Image(:, :, 1);

%% Recalibrate lattice R
LatCalib.Andor19330.calibrateR(signal2(1:512, :));
LatCalib.Andor19331.calibrateR(signal(1:512, :));

%% Transform Andor19330 image (2) to Andor19331 coordinates

% All pixels coordinates in Andor19331 frame
x_range = 1:512;
y_range = 1:1024;
[Y, X] = meshgrid(y_range, x_range);
corr = [X(:), Y(:)];

% Corresponding pixel position in Andor19330 frame
[corr2, lat_corr] = Lat19331.convertCross(Lat19330, corr);

% Get the pixel value in Andor19330 frame at transformed coordinates
value2 = reshape(getPixelValue(corr2, signal2), 1024, 1024);

%% Show transformed image
close all

figure
imagesc(value2)
axis image
colorbar
Lat19331.plot()
title('Transformed from Andor19330')

figure
imagesc(signal)
axis image
colorbar
Lat19331.plot()
title('Original Andor19331 image (Before cross calibration)')

figure
imagesc(signal2)
axis image
colorbar
Lat19330.plot()
title('Original Andor19330 image')

%% Maximize overlapping by calculating cosine similarity

Lat19331_R = Lat19331.R;

sites = Lat19331.convert2Real(Lattice.prepareSite('hex', 'latr', 20));
score = zeros(1, size(sites, 1));
for i = 1:size(sites, 1)
    Lat19331.init(sites(i, :));
    corr2 = Lat19331.convertCross(Lat19330, corr);
    value2 = reshape(getPixelValue(corr2, signal2), 1024, 1024);
    score(i) = 1 - pdist2(signal(:)', value2(:)', "cosine");
end

%% Reset the calibration
close all

[max_score, max_idx] = max(score);
Lat19331.init(sites(max_idx, :));
corr2 = Lat19331.convertCross(Lat19330, corr);
value2 = reshape(getPixelValue(corr2, signal2), 1024, 1024);

figure
imagesc(value2)
axis image
colorbar
Lat19331.plot()
title('Transformed from Andor19330')

figure
imagesc(signal)
axis image
colorbar
Lat19331.plot()
title('Original Andor19331 (After cross calibration)')

%%

function value = getPixelValue(corr, signal, x_range, y_range)
    arguments
        corr
        signal
        x_range = 1: size(signal, 1)
        y_range = 1: size(signal, 2)
    end
    good_idx = (corr(:, 1) >= x_range(1)) & (corr(:, 1) <= x_range(end)) ...
        & (corr(:, 2) >= y_range(1)) & (corr(:, 2) <= y_range(end));
    value = zeros(size(corr, 1), 1);
    x_size = size(signal, 1);
    value(good_idx) = signal(corr(good_idx, 1) + (corr(good_idx, 2)-1) * x_size);
end
