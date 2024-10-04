% script to look at the different readout noises
% load the data
data1Mhz = load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_1MHz.mat');
data3Mhz= load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_3MHz.mat');
data5Mhz = load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_5MHz.mat');
%% load the cropped data
data1Mhz = load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_1MHz_cropped.mat');
data3Mhz= load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_3MHz_cropped.mat');
data5Mhz = load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2024\09 September\20240926 camera readout noise\clean_bg_5MHz_cropped.mat');
% cropped1 = 
% cropped3 = 
% cropped5=
data1 = data1Mhz.Data.Andor19330.Image;
var1 = var(double(data1Mhz.Data.Andor19330.Image(:)));

data3 = data3Mhz.Data.Andor19330.Image;
var3 = var(double(data3Mhz.Data.Andor19330.Image(:)));

data5 = data5Mhz.Data.Andor19330.Image;
var5 = var(double(data5Mhz.Data.Andor19330.Image(:)));

speeds = [1; 3; 5];
vars = [var1; var3; var5];
figure;
scatter(speeds,vars,'or','filled');
hold on
xlabel('Readout speed (MHz)')
ylabel('Variance')
title('variance vs. camera readout speed')
%%
% figure
% subplot(1,3,1)
% imagesc(var(data1Mhz.Data.Andor19330.Image(:)));
% daspect([1 1 1]);
% title('1 MHz readout');
% colorbar
% caxis([0 5000]);
% subplot(1,3,2)
% imagesc(var(data3Mhz.Data.Andor19330.Image(:)));
% daspect([1 1 1]);
% title('3 MHz readout');
% colorbar
% caxis([0 5000]);
% subplot(1,3,3)
% imagesc(var(data5Mhz.Data.Andor19330.Image(:)));
% daspect([1 1 1]);
% title('5 MHz readout');
% colorbar
% caxis([0 5000]);

