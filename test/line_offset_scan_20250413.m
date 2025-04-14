clear; clc; close all
p = Preprocessor();

%%
Data = load("data/2025/03 March/20250303 triggered moving circles/triggered_movie_black_circle_r=50_step=2.mat").Data;
Signal = p.process(Data);

mean_signal = mean(Signal.Andor19330.Image, 3);
signal = Signal.Andor19330.Image;

%%
x_range = 120: 320;
y_range = 350: 550;

figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, mean_signal(x_range + 512, y_range))
clim([0 50])

subplot(1, 2, 2)
imagesc2(y_range, x_range, mean_signal(x_range, y_range))
clim([0 50])

figure
subplot(1, 2, 1)
imagesc2(signal(x_range + 512, y_range, 1))
% clim([0 100])

subplot(1, 2, 2)
imagesc2(signal(x_range, y_range, 1))
