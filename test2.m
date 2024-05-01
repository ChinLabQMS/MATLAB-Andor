%%
data_path = 'data/r=50_darkspot_onatoms_centered.mat';
Data = load(data_path).Data;

images = Data.Andor19330.Image;
mean_image = mean(images, 3);
figure; imagesc(mean_image); axis image; colorbar;