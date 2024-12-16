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
    "LatCalibFilePath", "calibration/LatCalib_20241213.mat", ... 
    "DataPath", "data/2024/12 December/20241213/singlesite_20241213.mat", ...
    "InitCameraName", ["Andor19330", "Andor19331", "Zelux", "DMD"], ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"]);

%% Recalibrate the lattice to new dataset
% Check diagnostic outputs to make sure all fits are reasonable

p.recalibrate( ...
    "reset_centers", 1, ...
    "calibO", 1, "signal_index", 1, ...
    "sites", Lattice.prepareSite('hex', 'latr', 20), ...
    "plot_diagnosticV", 1, ...
    "plot_diagnosticR", 1, ...
    "plot_diagnosticO", 1)

%% Save re-calibration result (default is with today's date)
close all
p.save()
