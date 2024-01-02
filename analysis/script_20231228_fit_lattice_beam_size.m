path = 'D:\QMS DATA\2023\12 December\2023-12-28 Beam size fitting';
file = 'top_right.asc';

image = readmatrix(fullfile(path, file), "FileType","text");
image = image(:, 2:end);

figure
imagesc(image)
daspect([1 1 1])
colorbar

%%
[gaussFit, GOF] = fit2dGaussian(image);