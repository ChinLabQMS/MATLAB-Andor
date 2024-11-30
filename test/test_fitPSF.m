%% Loading the raw dataset
clear; clc; close all
% DataPath = "data/2024/11 November/20241126 sparse/sparse_upper_not_on_focus.mat";
DataPath = "calibration/temp/20240903/20240903_align_lattice_and_DMD_sparse_exp=1.45s_both_upper_and_lower.mat";
Data = load(DataPath, "Data").Data;
Signal = Preprocessor().process(Data);
p = PointSource();

%% Visualize a sample image

p.fit(Signal.Andor19330.Image(:, :, 6), 'verbose', 1, 'plot_diagnostic', 0)
