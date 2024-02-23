mean_background = mean(Data.Background, 3);
mean_image = mean(Data.Image, 3);
mean_signal = mean_image - mean_background;

figure
imagesc(mean_signal)
daspect([1 1 1])
