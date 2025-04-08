clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;

p = Preprocessor();
Signal = p.process(Data);

signal = mean(Signal.Andor19331.Image(:, :, 1), 3);
counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;

%%
stat1 = counter.process(signal, 2, 'plot_diagnostic', 0, 'count_method', "circle_sum");
stat2 = counter.process(signal, 2, 'plot_diagnostic', 0, 'count_method', "center_signal");

%%
figure
histogram(stat1.LatCount, 100)

figure
histogram(stat2.LatCount, 100)

%%
figure
scatter(stat2.LatCount(:, 1), stat2.LatCount(:, 2))

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

%%
figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, rec_signal)
lat.plot()
subplot(1, 2, 2)
imagesc2(y_range, x_range, signal(x_range, y_range))
lat.plot()

%%
[M, x_range, y_range] = counter.getSpreadMatrix();

figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, reshape(M(1,:), length(x_range), length(y_range)))
subplot(1, 2, 2)
ps.plot()

%%
weights = counter.getDeconvWeight();

%%
idx = weights{100}(:, 1);
val = weights{100}(:, 2);
site_count = signal(idx) * val'


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
