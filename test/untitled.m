clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
% Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;
% Data = load("data/2025/04 April/20250408 mod freq scan/sparse_no_green.mat").Data;
% Data = load("data/2025/04 April/20250411/counter_not_working_somehow.mat").Data;
Data = load("data/2025/04 April/20250411/dense_no_green.mat").Data;

%%
p = Preprocessor();
Signal = p.process(Data);

signal = Signal.Andor19331.Image;
counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;
counter.SiteGrid.config("SiteFormat", "Hex", "HexRadius", 8)

%%
figure
imagesc2(mean(signal, 3))
clim([0, 100])
% counter.Lattice.plot()

%%
tic
stat = counter.process(signal, 2, 'plot_diagnostic', 0);
toc

%%
close all
figure
scatter(reshape(stat.LatCount(:, 1, 10), [], 1), reshape(stat.LatCount(:, 2, 10), [], 1))
xline(stat.LatThreshold)
axis("equal")

figure
histogram(stat.LatCount(:, :, 1), 100)
xline(stat.LatThreshold)

desc = counter.describe(stat.LatOccup, 'verbose', true);
