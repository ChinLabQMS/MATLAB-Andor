%% Introduction
% Goal: Generate a file containing PSF calibration for different cameras. 

%% Create a PSFCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to lattice calibration file to use
% - DataPath: path to .mat data file for this calibration. PSF calibration 
%             should work in sparse settings
% - PSFCameraList: list of camera names for calibrating PSF
% - PSFImageLabel: corresponding list of image labels for PSF calibration

clear; clc; close all
p = PSFCalibrator( ...
    "DataPath", "calibration/example_data/20241205_example_data.mat", ...
    "PSFCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "PSFImageLabel", ["Image", "Image", "Pattern_532"]);

%% Check signals, should be sparse
p.plot()

%% Process all cameras
% Note that for larger aberration, need to use different parameters

p.fit('Andor19330')
p.fit('Andor19331')
p.fit('Zelux', 'filter_box_max', inf, 'filter_gausswid_max', inf, 'refine_method', "COM")

%% PSF results
clc
p.PSFCalib.Andor19330

%%
clc
p.PSFCalib.Andor19331

%%
clc
p.PSFCalib.Zelux

%% PSF plots
p.plotPSF('Andor19330')
p.plotPSF('Andor19331')
p.plotPSF('Zelux')

%%
close all
p.save()
