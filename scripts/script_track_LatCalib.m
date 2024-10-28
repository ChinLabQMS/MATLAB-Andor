%% Create a Calibrator object
clear; clc;
p = LatCaliberator;

%% Config DataPath

p.config( ...
    "LatCalibFilePath", "calibration/LatCalib_20241002.mat", ...
    "DataPath", "data/2024/10 October/20241021 DMD alignment/BIG300_anchor=64_array64_spacing=100_centered_r=20_r=10.mat")

%%
res = p.trackCalib();
