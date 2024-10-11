%% Create a BkgStatGenerator
clear; clc
p = BkgStatGenerator;

%% Configure the file paths

% Alternatively, go to "/core/postprocess/BkgStatGeneratorConfig" and modifty
% the settings directly
p.config("DataPath", "data/2024/09 September/20240926 camera readout noise/", ...
    "Full_1MHz", "clean_bg_1MHz.mat", ...
    "Cropped_1MHz", "clean_bg_1MHz_cropped.mat", ...
    "Full_3MHz", "clean_bg_3MHz.mat", ...
    "Cropped_3MHz", "clean_bg_3MHz_cropped.mat", ...
    "Full_5MHz", "clean_bg_5MHz.mat", ...
    "Cropped_5MHz", "clean_bg_5MHz_cropped.mat")
disp(p)

%% Generate background statistics
p.process()
disp(p.BkgStat)

%% Plot some diagnostic figures
p.plot("Full_1MHz", "Andor19330")

%% Save the calibration to file
p.save()
