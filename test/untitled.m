clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
% Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;
Data = load("data/2025/04 April/20250408 mod freq scan/sparse_no_green.mat").Data;

p = Preprocessor();
Signal = p.process(Data);

% signal = mean(Signal.Andor19331.Image(:, :, 1), 3);
signal = Signal.Andor19331.Image;
counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;

%%
tic
counter.updateSiteProp(1:512, 1:1024)
toc

%%
close all
stat1 = counter.process(signal, 2, 'plot_diagnostic', 1, 'count_method', "circle_sum");
stat2 = counter.process(signal, 2, 'plot_diagnostic', 1, 'count_method', "center_signal");
stat3 = counter.process(signal, 2, 'plot_diagnostic', 1, 'count_method', "linear_inverse");

%%
figure
histogram(stat1.LatCount, 100)

figure
histogram(stat2.LatCount, 100)

figure
histogram(stat3.LatCount, 100)

%%
close all
figure
scatter(reshape(stat3.LatCount(:, 1, :), [], 1), reshape(stat3.LatCount(:, 2, :), [], 1))
axis("equal")

%%
figure
subplot(1, 2, 1)
imagesc2(signal)

subplot(1, 2, 2)
imagesc2(signal)
lat.plot()
lat.plotV()
lat.plotOccup(stat2.SiteInfo.Sites(stat2.LatOccup(:, 1), :), stat2.SiteInfo.Sites(~stat2.LatOccup(:, 1), :))

%%
[rec_signal, x_range, y_range] = counter.reconstructSignal(stat2.SiteInfo.Sites, stat2.LatCount(:, 1));

figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, rec_signal)
lat.plot()
subplot(1, 2, 2)
imagesc2(y_range, x_range, signal(x_range, y_range))
lat.plot()

%%
[M, x_range, y_range] = counter.getSpreadMatrix('spread_sparse', true);

figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, reshape(M(1,:), length(x_range), length(y_range)))
subplot(1, 2, 2)
ps.plot()

%%
tic
[weights, centers] = counter.getDeconvWeight();
toc

%%
counts = weights * reshape(signal(x_range, y_range), [], 1);

%%
histogram(counts, 100)

%%
figure
imagesc2(signal)
hold on
scatter3(y, x, val, 20, val, 'filled')
scatter(centers(102, 2), centers(102, 1), 'r')

%%


%%
sites = SiteGrid.prepareSite("Rect", "latx_range", -20:5:20, "laty_range", -20: 5: 20);
Andor19331.plot(sites, 'color', 'w', 'norm_radius', 0.5, 'filter', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])

%%
Zelux.calibrateR(Signal.Zelux.Pattern_532(:, :, 1))

figure
imagesc2(Signal.Zelux.Pattern_532(:, :, 1))
Zelux.plot()
Zelux.plotV()
