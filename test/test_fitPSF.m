%% Loading the raw dataset
clear; clc; close all
DataPath = "data/2024/11 November/20241126 sparse/sparse_upper_not_on_focus.mat";
% DataPath = "calibration/temp/20240903/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);

%% Visualize a sample image

figure
imagesc2(Signal.Andor19330.Image(:, :, 2))

%%

p = PointSource("Andor19331");
p.reset()
p.fit(Signal.Andor19331.Image, 'verbose', 1, 'plot_diagnostic', 0, 'crop_radius', [30, 30], ...
    'filter_box_max', [20, 20], 'filter_gausswid_max', 5)
p.plot()

%%

p = PointSource("Andor19330");
p.reset()
p.fit(Signal.Andor19330.Image, 'verbose', 1, 'plot_diagnostic', 0, 'crop_radius', [30, 30])
p.plot()
