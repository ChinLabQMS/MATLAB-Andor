%% Introduction
% Goal: Generate a file containing lattice calibration for different 
% cameras. Lattice calibrations are labeled as its corresponding camera
% name.
% The physical lattice spacing is assumed to be equal for all the
% frames, which is 2*0.935/(3*sin(45 deg)) = 0.8815 um. This value
% serves as a ruler to calibrate the imaging magnification.

% Note that this script is for **FIRST** calibration that starts from no
% prior knowledge of the lattice geometry. Script_3 is available for 
% re-calibration from an existing calibration file.

% The most important calibration results obtained are:
% 1. Lattice vectors (V) 
% 2. Lattice offset (R)
% Together they gives the affine transformation between the physical 
% lattice frame and the camera frame

% Both lattice calibration (V, R) and PSF calibration are necessary to
% reconstruct counts at a given lattice site. To calibrate PSF, run the
% script_6.

%% Create a LatCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to pre-calibration file to use, leave empty for 
%                     the first calibration
% - DataPath: path to .mat data file for this calibration. Lattice
%             calibration should work in both sparse and dense settings
% - InitCameraName: calibrations to create upon initialization, named as the
%                   corresponding device, say, cameras/DMD
% - LatCameraList: list of camera names for calibrating lattice V and R
% - LatImageLabel: corresponding list of image labels for lattice
%                  calibration

clear; clc; close all
p = LatCalibrator( ... 
    "LatCalibFilePath", [], ...
    "DataPath", "calibration/example_data/20241205_example_data.mat", ...% "data/2024/12 December/20241205/sparse_with_532_r=2.mat", ...
    "InitCameraName", ["Andor19330", "Andor19331", "Zelux", "DMD"], ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"]);

%% Andor19330: Plot FFT of a small box centered at atom cloud
close all
p.plotFFT("Andor19330")

%% Andor19330: Input center of lattice and initial peak positions as [x1, y1; x2, y2]
% Select the *first* and *second* peaks to the right, clockwise from 12 o'clock
% The consistent peak selection is important to align the lattice axis
% among different frames.

close all
p.calibrate("Andor19330", [120, 236; 181, 279], 'plot_diagnosticR', 1, 'plot_diagnosticV', 1)

%% Andor19331: Plot FFT of a small box centered at atom cloud
close all
p.plotFFT("Andor19331")

%% Andor19331: Input the peaks that corresponds to the Andor19330 peaks under its coordinates
% Select the *second* and *first* peaks to the right, clockwise
% This is to align the vectors with the vectors selected for Andor19330

close all
p.calibrate("Andor19331", [167, 271; 123, 207], 'plot_diagnosticR', 1, 'plot_diagnosticV', 1)

%% Zelux: Plot FFT of the entire image
% Note that Zelux image has larger magnification and more noisy.
% Discretization improves the signal for atom image, but not for lattice
% images.

close all
p.plotFFT("Zelux")

%% Zelux: Input the peaks positions
% Input in the orientation similar to Andor19330 to align lattice vectors
% Set 'binarize' to 0 to disable binarization in the calibration

close all
p.calibrate("Zelux", [658, 565; 714, 595], 'binarize', 0, 'plot_diagnosticR', 1, 'plot_diagnosticV', 1)

%% Cross-calibrate Andor19331 to Andor19330
close all
p.calibrateO(1, 'sites', Lattice.prepareSite('hex', 'latr', 20), 'plot_diagnosticO', 1)

%% (optional) Calibrate to a different signal index by searching a smaller region
p.calibrateO(20, 'sites', Lattice.prepareSite('hex', 'latr', 2), 'plot_diagnosticO', 0)

%% Save lattice calibration of all three cameras (default is with today's date)
p.save()

%% [IMPORTANT] Update the class definition
% Update the 'LatCalibFilePath' in those classes after each (re)calibration
% to make sure the future analysis will be with up-to-date calibration
% - LatProcessor: "/core/postprocess/LatProcessor.m"
%       This is to use the new calibration as default for future 
%       lattice-related live and post-analysis