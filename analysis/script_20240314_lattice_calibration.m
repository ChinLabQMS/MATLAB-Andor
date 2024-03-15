%% Load the dataset
Data = load("calibration/Data_for_PSF_fitting_test.mat").Data;
Background = load("calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat");

%%
images = double(Data.Andor19331.Image) - Background.Andor19331.SmoothMean;
mean_image = mean(images, 3);

figure
imagesc(mean_image)
daspect([1 1 1])
colorbar

%%


%%

fft_mean = abs(fftshift(fft(mean_image)));

imagesc(log(fft_mean))
daspect([1 1 1])
colorbar

%%
f = parfeval(backgroundPool,@magic,1,3);
fetchOutputs(f)