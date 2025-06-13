clear; clc; close all

Data = load("data/2025/05 May/20250522/calibrated_transport_r=20_with_iris_-5to4site_alongv1_again2.mat").Data;
template_start = imread("data/2025/05 May/20250522/sequence/black_moving_circle_v1_r=20_start=-4.0_end=5.0_step=0.1/template/GRB_1_black_moving_circle.bmp");
template_end = imread("data/2025/05 May/20250522/sequence/black_moving_circle_v1_r=20_start=-4.0_end=5.0_step=0.1/template/GRB_6_black_moving_circle.bmp");
load("calibration/dated_LatCalib/LatCalib_20250522_225124.mat");

p = Preprocessor();
Signal = p.process(Data);

signal = Signal.Andor19331.Image;
mean_signal = mean(signal, 3);

%%
figure
imagesc2(signal(:,:,1))
Andor19331.plot()

%% averaged image
x_range = 220: 280;
y_range = 560: 680;

figure
subplot(1, 2, 1)
imagesc(y_range, x_range, mean_signal(x_range + 512, y_range))
daspect([1 1 1])

subplot(1, 2, 2)
imagesc(y_range, x_range, mean_signal(x_range, y_range))
daspect([1 1 1])

%% single shot
index = 1;

figure
subplot(1, 2, 1)
imagesc(y_range, x_range, signal(x_range + 512, y_range, index))
daspect([1 1 1])
xticks([])
yticks([])
clim([10, inf])
line([y_range(1) + 10, y_range(1) + 10 + 33.6], ...
     [x_range(end) - 10, x_range(end) - 10], ...
     'Color', 'w', 'LineWidth', 3)

subplot(1, 2, 2)
imagesc(y_range, x_range, signal(x_range, y_range, index))
daspect([1 1 1])
xticks([])
yticks([])
clim([10, inf])
line([y_range(1) + 10, y_range(1) + 10 + 33.6], ...
     [x_range(end) - 10, x_range(end) - 10], ...
     'Color', 'w', 'LineWidth', 3)

%% transformed pattern
transformed_start = DMD.transformSignal(Andor19331, x_range, y_range, template_start);
transformed_end = DMD.transformSignal(Andor19331, x_range, y_range, template_end);

figure
subplot(1, 2, 1)
imagesc(transformed_start)
daspect([1 1 1])
colormap('gray')
xticks([])
yticks([])

subplot(1, 2, 2)
imagesc(transformed_end)
daspect([1 1 1])
xticks([])
yticks([])
