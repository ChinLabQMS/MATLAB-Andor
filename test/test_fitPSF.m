%% Loading the raw dataset
clear; clc; close all
DataPath = "data/2024/12 December/20241205/sparse_with_532_r=2.mat";
% DataPath = "data/2024/11 November/20241126 sparse/sparse_upper_not_on_focus.mat";
% DataPath = "data/2024/11 November/20241113 sparse warmup/warmup_sparse.mat";
% DataPath = "calibration/temp/20240903/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);

%% Visualize a sample image
figure
imagesc2(Signal.Andor19330.Image(:, :, 20), 'title', 'Andor19330')

%%
figure
imagesc2(Signal.Andor19331.Image(:, :, 20), 'title', 'Andor19331')

%%
figure
imagesc2(Signal.Zelux.Pattern_532(:, :, 1))

%%
p = PointSource("Andor19331");
p.fit(Signal.Andor19331.Image, 'plot_diagnostic', 0)

%%
p.plot()

%%
p = PointSource("Andor19330");
p.fit(Signal.Andor19330.Image, 'plot_diagnostic', 0)

%%
p.plot()

%%
p = PointSource("Zelux", 10.6);
p.fit(Signal.Zelux.Pattern_532, 'plot_diagnostic', 0, ...
    'filter_box_min', 0, 'filter_box_max', inf, 'filter_gausswid_max', inf, 'refine_method', "COM")

%%
p.plot("show_gauss_surface", 0)
