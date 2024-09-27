% test Zelux lattice calibration
% script to create precalibration for lattice on Zelux camera
% Zelux lattice calibration script.

% start by loading in data- image of the lattice from the Zelux camera
% manipulate it so I can save a .mat with just that image of the lattice.
figure;
% imagesc(Data.Zelux.Lattice(:,:,2)); % this is an image of the DMD pattern
imagesc(Data.Zelux.DMD(:,:,2)); % this is an image of the lattice. Good!!
daspect([1 1 1]);

zeluxlatdata = Data.Zelux.DMD(:,:,2);

load('zeluxlatdata.mat');
Data = zeluxlatdata;

figure;
imagesc(zeluxlatdata)
daspect([1 1 1]);

% doing some work to get the initial fft and find the lattice vectors!!
using code from test_lattice_calibration.m in
Matlab>Matlab-Andor>analysis
initialize a structure
Lattice = struct('Zelux', struct());
%%
signal = zeluxlatdata(1:1080,:); % square crop it
FFT2 = abs(fftshift(fft2(signal)));

figure
imagesc((FFT2))
daspect([1 1 1])
colorbar

%% Zelux Lattice Peaks
peak_init = [496 511;
             493 566;
             538 595];

[size_x, size_y] = size(FFT2);
center_x = floor(size_x / 2);
center_y = floor(size_y / 2);

Lattice.Zelux.K = (peak_init-[center_x, center_y])./size_x;
Lattice.Zelux.V = (inv(Lattice.Zelux.K(1:2,:)))';
Lattice.Zelux.R = [541, 541];

%%
[Y, X] = meshgrid(-10:10, -10:10);
Y = Y(:);
X = X(:);

corr = [Y, X] * Lattice.Zelux.V + Lattice.Zelux.R;

figure
imagesc(signal)
hold on
scatter(corr(:, 2), corr(:, 1),'r')
daspect([1 1 1])
colorbar