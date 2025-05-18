% script to load the images of the various traps from 2025-05-07 and find
% where each of them is centered- decide whether to move the DMD or the
% lattice

lattice = load("data\2025\05 May\20250507\latticeonandor19330_fixedexposure.mat").Data.Andor19330.Image(1:600,1:700,2);

whiteDMD = load("data\2025\05 May\20250507\whitedmdonlowerandor_fixedexposure_brighter.mat").Data.Andor19330.Image(1:600,1:700,2);

star = load("data\2025\05 May\20250507\staronlowerandor_fixedexposure.mat").Data.Andor19330.Image(1:600,1:700,2);

hashonatoms = load("data\2025\05 May\20250507\retryforcalibration.mat").Data.Andor19330.Image(1:600,1:700,:);

%%
figure;
subplot(1,4,1);
imagesc(lattice);
daspect([1 1 1]);
colorbar;

subplot(1,4,2);
imagesc(whiteDMD);
daspect([1 1 1]);
colorbar;

subplot(1,4,3);
imagesc(star);
daspect([1 1 1]);
colorbar;

subplot(1,4,4);
imagesc(mean(hashonatoms,3));
daspect([1 1 1]);
colorbar;

%%
figure;
imagesc(mean(hashonatoms,3));
daspect([1 1 1]);
colorbar;

%% looking at vec1 line on atoms
vec1lineonatoms = load("data\2025\05 May\20250507\vec1_lineonatoms.mat").Data.Andor19330.Image;
vec2lineonatoms = load("data\2025\05 May\20250507\vec2onatoms.mat").Data.Andor19330.Image;
figure;
imagesc(mean(vec1lineonatoms,3));
daspect([1 1 1]);
colorbar;

figure;
imagesc(mean(vec2lineonatoms,3));
daspect([1 1 1]);
colorbar;

linearray2 = load("data\2025\05 May\20250507\actual_vec2onatoms.mat").Data.Andor19330.Image;
figure;
imagesc(mean(linearray2,3));
daspect([1 1 1]);
colorbar;
