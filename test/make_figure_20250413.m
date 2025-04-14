clear; clc; close all
p = Preprocessor();

% Good dataset with <5% error rate
Data = load("data/2025/04 April/20250411/dense_no_green.mat").Data;
Signal = p.process(Data);
signal = Signal.Andor19331.Image;
grid = SiteGrid("SiteFormat", "Hex", "HexRadius", 12);
counter = SiteCounter("Andor19331", [], [], grid);
counter2 = SiteCounter("Andor19330", [], [], grid);

%%
counter.Lattice.init([245, 645], 'format', 'R')
tic
stat = counter.process(signal, 2, 'plot_diagnostic', 0, 'classify_threshold', 1300, ...
    'calib_mode', 'offset', 'classify_method', 'single');
toc

%% Plot deconvolution kernel
figure('Position', [500, 500, 250, 250])
counter.plotDeconvFunc()
lat.plot('center',[0,0], 'filter', true, 'diff_origin', false, 'norm_radius', 0.02, 'line_width', 1.5, 'color', 'w')
xlim([-15, 15])
ylim([-15, 15])
xticks([])
yticks([])

%% Draw a sample image with scalebar and zoom in box
close all

% Cropped region
x_range = 20: 420;
y_range = 430:830;
% Scale bar
scalebar_length = 20; % um
scalebar_lengthpx = scalebar_length * lat.PixelPerUm;
scalebar_x = x_range(end) - 15;
scalebar_y = y_range(1) + 10;
% Small box
box_x = 220;
box_y = 620;
box_h = 50;
box_w = 50;
box_xrange = box_x : box_x + box_h - 1;
box_yrange = box_y : box_y + box_w - 1;
% Scalebar on small box
scalebar2_length = 1;
scalebar2_lengthpx = scalebar2_length * lat.PixelPerUm;
scalebar2_x = box_xrange(end) - 3;
scalebar2_y = box_yrange(1) + 3;

figure
imagesc(y_range, x_range, signal(x_range, y_range, 1))
axis("image")
cb = colorbar('westoutside');
xticks([])
yticks([])
set(cb, 'FontSize', 14);
clim([10, 170])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 30, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');
rectangle('Position', [box_y, box_x, box_w, box_h], 'LineWidth', 0.75, 'EdgeColor', 'w')

figure('Position', [500, 500, 300, 300])
imagesc(box_yrange, box_xrange, signal(box_xrange, box_yrange))
axis('image')
xticks([])
yticks([])
clim([10, 170])
lat.plot('filter', false, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'k')
xlim([box_yrange(1), box_yrange(end)])
ylim([box_xrange(1), box_xrange(end)])
line([scalebar2_y, scalebar2_y + scalebar2_lengthpx], [scalebar2_x, scalebar2_x], 'Color', 'w', 'LineWidth', 4)
text(scalebar2_y + scalebar2_lengthpx + 5, scalebar2_x - 0.5, ...
    [num2str(scalebar2_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

%% Show IMG1 and IMG2

index = 4;

% Cropped region
x_range = 165: 325;
y_range = 560: 720;
% Scale bar
scalebar_length = 5; % um
scalebar_lengthpx = scalebar_length * lat.PixelPerUm;
scalebar_x = x_range(end) - 15;
scalebar_y = y_range(1) + 10;

occup1 = reshape(stat.LatOccup(:, 2, index), [], 1);
occup2 = reshape(stat.LatOccup(:, 1, index), [], 1);
sites10 = stat.SiteInfo.Sites(occup1 & ~occup2, :);
sites01 = stat.SiteInfo.Sites(~occup1 & occup2, :);

figure('Position', [500, 500, 800, 400])
subplot(1, 2, 1)
imagesc(y_range, x_range, signal(x_range, y_range, index))
axis("image")
xticks([])
yticks([])
clim([10, 170])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 20, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');
lat.plot(sites01, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'b', 'line_width', 1.5)
lat.plot(sites10, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'r', 'line_width', 1.5)
% lat.plot(stat.SiteInfo.Sites)

subplot(1, 2, 2)
imagesc(y_range, x_range, signal(x_range + 512, y_range, index))
axis("image")
xticks([])
yticks([])
clim([10, 170])
line([scalebar_y, scalebar_y + scalebar_lengthpx], [scalebar_x, scalebar_x], 'Color', 'w', 'LineWidth', 3)
text(scalebar_y + scalebar_lengthpx + 20, scalebar_x - 1.5, ...
    [num2str(scalebar_length) ' \mum'], ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');
lat.plot(sites01, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'b', 'line_width', 1.5)
lat.plot(sites10, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'r', 'line_width', 1.5)

%% Show reconstructed occupancy in the small box

occup = reshape(stat.LatOccup(:, 1, 1), [], 1);

figure('Position', [500, 500, 300, 300])
imagesc(box_yrange, box_xrange, signal(box_xrange, box_yrange))
lat.plotOccup(stat.SiteInfo.Sites(occup, :), zeros(0, 2), 'radius', 0.5, 'occup_color', 'w')
axis('image')
xticks([])
yticks([])
clim([10, 170])
xlim([box_yrange(1), box_yrange(end)])
ylim([box_xrange(1), box_xrange(end)])

figure('Position', [500, 500, 300, 300])
lat.plotCounts(stat.SiteInfo.Sites, double(occup), 'scatter_radius', 5)
xlim([box_yrange(1), box_yrange(end)])
ylim([box_xrange(1), box_xrange(end)])
xticks([])
yticks([])
colormap('gray')

%% Draw the histogram of counts distribution
counts = stat.LatCount(:);

[hcounts, hedges] = histcounts(counts, 100);
hcenters = (hedges(1: end - 1) + hedges(2: end)) / 2;

gmm = fitgmdist(counts, 2);

figure('Position', [500, 500, 400, 250])
histogram('BinCounts', hcounts, 'BinEdges', hedges, 'EdgeColor', 'none')
xline(stat.LatThreshold, 'LineWidth', 2, 'LineStyle', '--')
hold on
plot(hedges', pdf(gmm, hedges') * numel(counts) * (hedges(2) - hedges(1)), 'LineWidth', 2)
scatter(hcenters, hcounts, 20, 'filled', 'k')
box on
set(gca, 'LineWidth', 1);
ylabel('Occurrence')
xlabel('Counts')

%% Plot both upper and lower images
index = 3;

upper = Signal.Andor19331.Image(:, :, index);
lower = Signal.Andor19330.Image(:, :, index);

[upper_box, upper_x, upper_y] = prepareBox(upper, counter.Lattice.R, 100);
[lower_box, lower_x, lower_y] = prepareBox(lower, counter2.Lattice.R, 100);

counter.Lattice.calibrateR(upper_box, upper_x, upper_y)
counter2.Lattice.calibrateO(counter.Lattice, lower_box, upper_box, lower_x, lower_y, upper_x, upper_y)

%%
stat_upper = counter.process(Signal.Andor19331.Image, 2, 'calib_mode', 'update_range_only');
stat_lower = counter2.process(Signal.Andor19330.Image, 2, 'calib_mode', 'update_range_only');

%%
figure
subplot(2, 1, 1)
histogram(stat_lower.LatCount, 200)

subplot(2, 1, 2)
histogram(stat_upper.LatCount, 200)

%%
[upper_transformed] = counter.Lattice.transformSignalStandard(upper);
[lower_transformed, trans_x, trans_y, lat_transformed] = counter2.Lattice.transformSignalStandard(lower);

sites10 = stat.SiteInfo.Sites(stat_upper.LatOccup(:, 1, index) & ~stat_lower.LatOccup(:, 1, index), :);
sites01 = stat.SiteInfo.Sites(~stat_upper.LatOccup(:, 1, index) & stat_lower.LatOccup(:, 1, index), :);

figure('Position',[500, 500, 800, 400])
subplot(1, 2, 1)
imagesc(trans_y, trans_x, upper_transformed)
axis('image')
xticks([])
yticks([])
clim([0, 160])
xlim([-15, 15])
ylim([-15, 15])
line([-12, -7], [12, 12], 'Color', 'w', 'LineWidth', 3)
text(-3, 12, '5 \mum', ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');
lat_transformed.plot(sites01, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'b', 'line_width', 1.5)
lat_transformed.plot(sites10, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'r', 'line_width', 1.5)

subplot(1, 2, 2)
imagesc(trans_y, trans_x, lower_transformed)
axis('image')
xticks([])
yticks([])
clim([0, 140])
xlim([-15, 15])
ylim([-15, 15])
line([-12, -7], [12, 12], 'Color', 'w', 'LineWidth', 3)
text(-3, 12, '5 \mum', ...
    'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight','bold');
lat_transformed.plot(sites01, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'b', 'line_width', 1.5)
lat_transformed.plot(sites10, 'diff_origin', false, 'norm_radius', 0.5, 'color', 'r', 'line_width', 1.5)

%% Plot PSF of upper and lower cameras

figure
subplot(1, 2, 1)
imagesc(counter.PointSource.DataYRange, counter.PointSource.DataXRange, counter.PointSource.DataPSF)
axis("image")
xticks([])
yticks([])
counter.Lattice.plot('filter', true, 'center', [0, 0], ...
    'diff_origin', false, 'color', 'w', 'line_width', 2, 'norm_radius', 0.03)

subplot(1, 2, 2)
imagesc(counter2.PointSource.DataYRange, counter2.PointSource.DataXRange, counter2.PointSource.DataPSF)
axis("image")
xticks([])
yticks([])
counter2.Lattice.plot('filter', true, 'center', [0, 0], ...
    'diff_origin', false, 'color', 'w', 'line_width', 2, 'norm_radius', 0.03)
