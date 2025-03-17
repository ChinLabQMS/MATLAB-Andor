clear; clc; close all

Data = load("data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat").Data;
load("calibration/LatCalib.mat")

p = Preprocessor();
Signal = p.process(Data);

%%
template = imread("resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp");
signal = Signal.Zelux.Pattern_532(:, :, 1);
signal2 = mean(Signal.Andor19330.Image, 3);

%%
DMD.calibrateProjectorPattern(signal, 1: size(signal, 1), 1: size(signal, 2), Zelux)

%%

