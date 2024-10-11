clear; clc

Lat = load("calibration\LatCalib_20241002.mat");

%%
Lat.Andor19330.plotV()
Lat.Zelux.plotV()


%%

figure
imagesc(mean(Data.Zelux.DMD, 3))
axis image
colorbar

figure
imagesc(mean(Data.Andor19330.Image, 3))
axis image
colorbar