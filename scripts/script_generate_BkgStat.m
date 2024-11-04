%% Create a BkgStatGenerator and configure file paths
clear; clc
p = BkgStatGenerator( ...
    "DataDir", "data/2024/09 September/20240926 camera readout noise/", ...
    "Full_1MHz", "clean_bg_1MHz.mat", ...
    "Cropped_1MHz", "clean_bg_1MHz_cropped.mat", ...
    "Full_3MHz", "clean_bg_3MHz.mat", ...
    "Cropped_3MHz", "clean_bg_3MHz_cropped.mat", ...
    "Full_5MHz", "clean_bg_5MHz.mat", ...
    "Cropped_5MHz", "clean_bg_5MHz_cropped.mat");

% Alternatively, go to "/core/postprocess/BkgStatGenerator" and modify
% the settings directly
disp(p)

%% Generate background statistics
p.process()
disp(p.BkgSummary)

%% Plot some diagnostic figures
p.plot("Full_1MHz", "Andor19330")

%% Save the background offset and noise calibration to file
p.save()
