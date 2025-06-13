clear; clc; close all

Data = load("data/2025/04 April/20250414/lat_v3_-15_-10_-5_0_5_10_15.mat").Data;
load('calibration/dated_LatCalib/LatCalib_20250522_225124.mat')

%%
p = Preprocessor();
Signal = p.process(Data);

signal = Signal.Andor19331.Image;
mean_signal = mean(signal, 3);
counter = SiteCounter("Andor19331", Andor19331);
counter.SiteGrid.config("SiteFormat", "Rect", "RectRadiusY", 1, "RectRadiusX", 10)

%%
figure
imagesc2(signal(:,:,1))

%%
stat = counter.process(signal, 2, 'classify_method', 'fixed', 'fixed_thresholds', 400);

%%
index = 1;
x_range = 220: 280;
y_range = 560: 680;
scalebar_length = 5; % um
scalebar_lengthpx = scalebar_length * counter.Lattice.PixelPerUm;
scalebar_x = x_range(end) - 5;
scalebar_y = y_range(1) + 5;

figure
subplot(2, 1, 1)
imagesc(y_range, x_range, signal(x_range, y_range, index))
daspect([1  1 1])
xticks([])
yticks([])
% imagesc(y_range, x_range, mean(signal(x_range, y_range, :), 3))
% counter.Lattice.plot()
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 5)
% text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1, ...
%     [num2str(scalebar_length) ' \mum'], ...
%     'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight','bold');
clim([10, 80])

subplot(2, 1, 2)
imagesc(y_range, x_range, signal(x_range + 512, y_range, index))
daspect([1  1 1])
xticks([])
yticks([])
clim([10, 80])
% counter.Lattice.plot()
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 5)
% text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1, ...
%     [num2str(scalebar_length) ' \mum'], ...
%     'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight','bold');

%%
figure
subplot(2, 1, 1)
imagesc(y_range, x_range, mean(signal(x_range, y_range, :), 3))
daspect([1 1 1])
clim([0, 50])

subplot(2, 1, 2)
imagesc(y_range, x_range, mean(signal(x_range + 512, y_range, :), 3))
daspect([1 1 1])
clim([0, 50])

%% Image of averaged signal and single shot
close all
% Cropped region
x_range = 185: 325;
y_range = 555: 695;
% Scale bar
scalebar_length = 2; % um
scalebar_lengthpx = scalebar_length * counter.Lattice.PixelPerUm;
scalebar_x = x_range(end) - 5;
scalebar_y = y_range(1) + 5;

figure
imagesc(y_range, x_range, mean_signal(x_range, y_range))
axis("image")
xticks([])
yticks([])
% clim([20, 100])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 5)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'right', 'FontSize', 20, 'FontWeight','bold');

%%
figure
imagesc(y_range, x_range, signal(x_range, y_range, 5))
axis("image")
xticks([])
yticks([])
clim([10, 160])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 5)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'right', 'FontSize', 20, 'FontWeight','bold');

%% Occupancy statistics
stat = counter.process(signal, 2);

%% Local loss rate
early = reshape(sum(stat.LatOccup(:, 2, :), 3), [], 1);
later = reshape(sum(stat.LatOccup(:, 1, :), 3), [], 1);
loss = 1 - later ./ early;

figure
imagesc(y_range, x_range, mean_signal(x_range, y_range))
axis("image")
counter.Lattice.plot()

figure
counter.Lattice.plotCounts(stat.SiteInfo.Sites, loss, 'scatter_radius', 1)
cb = colorbar();
cb.FontSize = 18;
clim([0, 1])
xticks([])
yticks([])
xlim([y_range(1), y_range(end)])
ylim([x_range(1), x_range(end)])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 5)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'right', 'FontSize', 20, 'FontWeight','bold');

%%
% pattern = imread("data/2025/05 May/20250521/template/circle_array_python_r=5_step=5.bmp");
% pattern = imread("data/2025/04 April/20250414/template/V1=[-7.14, -7.76]_V2=[-10.43, 2.46]_offset=[-15, -10, -5, 0, 5, 10, 15]_width=5.bmp");
pattern = imread("data/2025/05 May/20250522/sequence/black_moving_circle_v1_r=20_start=-4.0_end=5.0_step=0.1/template/GRB_6_black_moving_circle.bmp");

transformed = DMD.transformSignal(counter.Lattice, x_range, y_range, pattern);
figure
imagesc(y_range, x_range, transformed)
xticks([])
yticks([])
daspect([1 1 1])
colormap('gray')
