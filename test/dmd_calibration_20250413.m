clear; clc; close all

% Data = load("data/2025/04 April/20250411/dense_calibration2.mat").Data;
% Data = load("data/2025/04 April/20250411/dmd_mod=80kHz_10ms_LatV3.mat").Data;
%%
p = Preprocessor();
Signal = p.process(Data);

signal = Signal.Andor19331.Image;
mean_signal = mean(signal, 3);
counter = SiteCounter("Andor19331", load('calibration/dated_LatCalib/LatCalib_20250414.mat').Andor19331);
counter.SiteGrid.config("SiteFormat", "Hex", "HexRadius", 15)

%% Image of averaged signal and single shot
close all
% Cropped region
x_range = 160: 300;
y_range = 545: 685;
% Scale bar
scalebar_length = 5; % um
scalebar_lengthpx = scalebar_length * counter.Lattice.PixelPerUm;
scalebar_x = x_range(end) - 15;
scalebar_y = y_range(1) + 10;

figure
imagesc(y_range, x_range, mean_signal(x_range, y_range))
axis("image")
xticks([])
yticks([])
clim([10, 100])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');

figure
imagesc(y_range, x_range, signal(x_range, y_range, 2))
axis("image")
xticks([])
yticks([])
clim([10, 160])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');

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
colorbar()
clim([0, 1])
xticks([])
yticks([])
xlim([y_range(1), y_range(end)])
ylim([x_range(1), x_range(end)])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 15, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');

