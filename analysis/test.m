%%
index = 5;
sample1 = Data.Andor19330.Image(:,:,index);
sample2 = Data.Andor19331.Image(:,:,index);

figure
subplot(1,2,1)
imagesc(sample1)
daspect([1 1 1])
colorbar

subplot(1,2,2)
imagesc(sample2)
daspect([1 1 1])
colorbar

%%
images = Data.Andor19330.Image;
background = load("calibration\StatBackground_20240327_HSSpeed=2_VSSpeed=1.mat").Andor19330.SmoothMean;
mean_image = mean(images, 3) - background;

figure
imagesc(mean_image);
daspect([1 1 1]);
title('Mean Image')
clim([0 50])
colorbar;