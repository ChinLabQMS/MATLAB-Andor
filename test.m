% mean_background = mean(Data.Background, 3);
% mean_image = mean(Data.Image, 3);
% mean_signal = mean_image - mean_background;
% 
% figure
% imagesc(mean_signal)
% daspect([1 1 1])

%%
meanimage = mean(Data.Andor19330.Image,3);
imagesc(meanimage)
daspect([1 1 1])
colorbar
 
%%
index = 1;
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
mean_image = mean(images, 3);

figure
imagesc(mean_image);
daspect([1 1 1]);
title('Mean Image')
colorbar;