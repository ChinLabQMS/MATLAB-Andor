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
    "DataPath", "data/2025/06 June/20250602/cal3.mat", ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"], ...
    "ProjectorList", "DMD");

%% Check an example shot on all the cameras
p.plotSignal(1)

%% Recalibrate the lattice to new dataset
% Check diagnostic outputs to make sure all fits are reasonable
close all
p.recalibrate( ...
    "reset_centers", 0, ...
    "calibO", 1, "signal_index", 1, "sites", SiteGrid.prepareSite('Hex', 'latr', 20), ... % Specify the shot index for cross calibration
    "plot_diagnosticV", 1, ...
    "plot_diagnosticR", 1, ...
    "plot_diagnosticO", 1)

%% Cross-calibrate Zelux and DMD with atom signal on Andor19331
% Please make sure that the projected signal is hash cross pattern
% Turn on debug mode such that only diagnostic plots are generated, the
% actual lattice parameters are not updated
close all
p.calibrateProjector('sites', SiteGrid.prepareSite('Hex', 'latr', 20), 'debug', false)

%% Pick the site with highest similarity and input the coordinate for calibrating Zelux
% Or directly run the calibration algorithm with debug mode off if the
% initial center is close
close all
%p.LatCalib.Zelux.init([704.867, 164.577], 'format', 'R')
%p.LatCalib.Zelux.init([773,305], 'format', 'R')
p.calibrateProjector('sites', SiteGrid.prepareSite('Hex', 'latr', 3, 'latr_step', 0.1), 'debug', false)

%% Plot an example shot of transformed images
p.plotTransformed("x_lim", [-30, 30], "y_lim", [-30, 30], "index", 1)

%% Plot the averaged signal to check full calibration
p.plotProjection("add_guide", true, 'raw_image', false)

%% Save re-calibration result
close all
p.save()
