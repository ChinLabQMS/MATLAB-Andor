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
% - InitCameraName: calibrations to create upon initialization, named as the
%                   corresponding device, say, cameras/DMD
% - LatCameraList: list of camera names for calibrating lattice V and R
% - LatImageLabel: corresponding list of image labels for lattice
%                  calibration

clear; clc; close all
p = LatCalibrator( ...
    "LatCalibFilePath", "calibration/LatCalib.mat", ... 
    "DataPath", "data/2025/02 Feburary/20250213/end_of_day.mat", ...
    "InitCameraName", ["Andor19330", "Andor19331", "Zelux", "DMD"], ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"]);

%% Check an example shot on all the cameras
p.plotSignal("index", 1)

%% Recalibrate the lattice to new dataset
% Check diagnostic outputs to make sure all fits are reasonable

p.recalibrate( ...
    "reset_centers", 1, ...
    "calibO", 1, "signal_index", 1, ...  % Specify the shot index for cross calibration
    "sites", SiteGrid.prepareSite('Hex', 'latr', 20), ...
    "plot_diagnosticV", 1, ...
    "plot_diagnosticR", 1, ...
    "plot_diagnosticO", 1)

%% Plot an example shot of transformed images
p.plotTransformed("x_lim", [-20, 20], "y_lim", [-20, 20], "index", 1)

%% Save re-calibration result
close all
p.save()
