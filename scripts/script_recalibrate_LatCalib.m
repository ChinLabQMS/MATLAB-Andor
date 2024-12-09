%% Re-calibrate the lattice to a new dataset
clear; clc; close all
% Set an initial calibration file location and new data location for re-calibration
p = LatCalibrator( ...
    "LatCalibFilePath", "calibration/LatCalib_20241210.mat", ... 
    "DataPath", "data/2024/12 December/20241205/sparse_with_532_r=2_big.mat");

%%
p.recalibrate( ...
    "reset_centers", 0, ...
    "calibO", 1, "signal_index", 1, ...
    "sites", Lattice.prepareSite('hex', 'latr', 20), ...
    "plot_diagnosticV", 1, ...
    "plot_diagnosticR", 0, ...
    "plot_diagnosticO", 1)

%% If the dataset contains sparse points for all cameras, calibrate PSF


%% Save re-calibration result (default is with today's date)
close all
p.save()
