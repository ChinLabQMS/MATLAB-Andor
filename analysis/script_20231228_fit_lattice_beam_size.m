% path = 'D:\QMS DATA\2023\12 December\2023-12-28 Beam size fitting';
path = 'D:\QMS DATA\2024\02 February\2024-02-02';
file = 'top_right_after.asc';

image = readAscImage(path, file);
fit2dGaussian(image, "offset",'linear');

%%
file = 'all_white_final.asc';

image = readAscImage(path, file);
[fit_result, x, y, z, output] = fit2dGaussian(image, "offset",'linear');

residuals = reshape(output.residuals, 1024, 1024);

figure
subplot(2,1,1)
imagesc(image)
daspect([1 1 1])
colorbar

subplot(2,1,2)
imagesc(residuals)
daspect([1 1 1])
colorbar