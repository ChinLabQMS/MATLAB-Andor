% May 2024 lattice calibration- Special Optics tube lenses, new mirror
% setup
%% Load the dataset
clear; clc;
Data = load("data/calibration_test_40shots.mat").Data;
Background = load("calibration\StatBackground_20240327_HSSpeed=2_VSSpeed=1.mat");
Lattice = struct('Config', Data.Andor19330.Config, ...
                 'Andor19330', struct(), ...
                 'Andor19331', struct());

%% Look at lower CCD (Andor 19330) images
images = double(Data.Andor19330.Image);
background = Background.Andor19330.SmoothMean;

mean_image = mean(images, 3) - background;
signal = (mean_image - cancelOffset(mean_image, 1));
signal = signal(2:end, 2:end);

figure
imagesc(signal)
daspect([1 1 1])
colorbar

%%
FFT2 = abs(fftshift(fft2(signal)));

figure
imagesc(log(FFT2))
daspect([1 1 1])
colorbar

%% Andor 19330
peak_init = [336 598;
             497 710;
             674 625];

[size_x, size_y] = size(FFT2);
center_x = floor(size_x / 2);
center_y = floor(size_y / 2);

Lattice.Andor19330.K = (peak_init-[center_x, center_y])./size_x;
Lattice.Andor19330.V = (inv(Lattice.Andor19330.K(1:2,:)))';
Lattice.Andor19330.R = [315, 545];

%%
[Y, X] = meshgrid(-10:10, -10:10);
Y = Y(:);
X = X(:);

corr = [Y, X] * Lattice.Andor19330.V + Lattice.Andor19330.R;

figure
imagesc(signal)
hold on
scatter(corr(:, 2), corr(:, 1))
daspect([1 1 1])
colorbar

%%
images = double(Data.Andor19331.Image);
background = Background.Andor19331.SmoothMean;

mean_image = mean(images, 3) - background;
signal = (mean_image - cancelOffset(mean_image, 1));
signal = signal(2:end, 2:end);

figure
imagesc(signal)
daspect([1 1 1])
colorbar

%%
FFT2 = abs(fftshift(fft2(signal)));

figure
imagesc(log(FFT2))
daspect([1 1 1])
colorbar

%% Andor 19331
peak_init = [317 523;
             422 686;
             618 675];

[size_x, size_y] = size(FFT2);
center_x = floor(size_x / 2);
center_y = floor(size_y / 2);

Lattice.Andor19331.K = (peak_init-[center_x, center_y])./size_x;
Lattice.Andor19331.V = (inv(Lattice.Andor19331.K(1:2,:)))';
Lattice.Andor19331.R = [260 600];