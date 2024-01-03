path = 'D:\QMS DATA\2023\12 December\2023-12-28 Beam size fitting';
file = 'bottom.asc';

image = readmatrix(fullfile(path, file), "FileType","text");
image = image(:, 2:end);

figure
imagesc(image)
daspect([1 1 1])
colorbar

%%
[fit_result, GOF, x, y, z] = fit2dGaussian(image, "offset", 'linear');

%%
residuals = z-fit_result(x, y);
residuals = reshape(residuals, 1024, 1024);

%%
figure
imagesc(residuals)
daspect([1 1 1])
colorbar