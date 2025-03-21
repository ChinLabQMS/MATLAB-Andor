%% Introduction
% Goal: Generate a file containing lattice calibration for different
% cameras.

% Note that this script is for "RE" calibration that starts from a loaded
% calibration file.

%% Create a LatCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to pre-calibration file to use
% - DataPath: path to .mat data file for this calibration. Lattice
%             calibration should work in both sparse and dense settings
% - LatCameraList: list of camera names for calibrating lattice V and R
% - LatImageLabel: corresponding list of image labels for lattice
%                  calibration

clear; clc; close all
p = LatCalibrator( ...
    "LatCalibFilePath", "calibration/LatCalib.mat", ... 
    "DataPath", "data/2025/03 March/20250312/dense_begin_of_day.mat", ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"]);

%% Check an example shot on all the cameras
p.plotSignal(1)

%% Recalibrate the lattice to new dataset
% Check diagnostic outputs to make sure all fits are reasonable

p.recalibrate( ...
    "reset_centers", 0, ...
    "calibO", 1, "signal_index", 1, "sites", SiteGrid.prepareSite('Hex', 'latr', 20), ... % Specify the shot index for cross calibration
    "plot_diagnosticV", 1, ...
    "plot_diagnosticR", 1, ...
    "plot_diagnosticO", 1)

%% Plot an example shot of transformed images
p.plotTransformed("x_lim", [-30, 30], "y_lim", [-30, 30], "index", 1)

%% Save re-calibration result
close all
p.save()
