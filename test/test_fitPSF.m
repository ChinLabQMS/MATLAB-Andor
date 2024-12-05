%% Loading the raw dataset
clear; clc; close all
% DataPath = "data/2024/11 November/20241126 sparse/sparse_upper_not_on_focus.mat";
DataPath = "data/2024/11 November/20241113 sparse warmup/warmup_sparse.mat";
% DataPath = "calibration/temp/20240903/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);

%% Visualize a sample image

figure
imagesc2(Signal.Andor19331.Image(:, :, 51))

%%
p = PointSource("Andor19331");
p.fit(Signal.Andor19331.Image(:, :, 31:40), 'verbose', 1, 'plot_diagnostic', 0, 'crop_radius', [30, 30], ...
    'filter_box_max', [30, 30], 'filter_gausswid_max', 5)

%%
figure
p.plot()

%%

p = PointSource("Andor19330");
p.reset()
p.fit(Signal.Andor19330.Image(:, :, 91:100), 'verbose', 1, 'plot_diagnostic', 0, 'crop_radius', [30, 30])
p.plot()
