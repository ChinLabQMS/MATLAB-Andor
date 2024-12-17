%% Introduction
% Goal: Generate a file containing PSF calibration for different cameras. 

%% Create a PSFCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to lattice calibration file to use
% - DataPath: path to .mat data file for this calibration. PSF calibration 
%             should work in sparse settings
% - PSFCameraList: list of camera names for calibrating PSF
% - PSFImageLabel: corresponding list of image labels for PSF calibration
% - PSFInitRatio: ratio of resolution to the ideal Rayleigh resolution,
%                 when using a value larger than 1, it assumes a worse
%                 area when doing fit and filtering

clear; clc; close all
p = PSFCalibrator( ...
    "DataPath", "calibration/example_data/20241205_example_data.mat", ...
    "PSFCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "PSFImageLabel", ["Image", "Image", "Pattern_532"], ...
    "PSFInitRatio", [1.3, 1.5, 4]);

%% Check signals, should be sparse
p.plotSignal()

%% Process single image, to check whether the filtering parameters are good
close all
p.fit('Andor19330', 1, 'plot_diagnostic', 1)
p.PSFCalib.Andor19330.plotPSF()

%% Andor19331
close all
p.fit('Andor19331', 1, 'plot_diagnostic', 1)

%% Zelux
close all
p.fit('Zelux', 1, 'plot_diagnostic', 1)

%% Process all data for each camera
close all
p.fit('Andor19330', [], 'verbose', 1)
p.PSFCalib.Andor19330.plotWidthDist()
p.PSFCalib.Andor19330.plotPSF()
p.PSFCalib.Andor19330

%% Andor19331
close all
p.fit('Andor19331', [], 'verbose', 1)
p.PSFCalib.Andor19331.plotWidthDist()
p.PSFCalib.Andor19331.plotPSF()
p.PSFCalib.Andor19331

%% Zelux
% Note that for Zelux that has larger magnification, it is better to use a
% different parameter for better recognition and faster execution
p.fit('Zelux', [], 'verbose', 1, 'refine_method', "COM", 'filter_gausswid_max', inf)
p.PSFCalib.Zelux.plotWidthDist()
p.PSFCalib.Zelux.plotPSF()
p.PSFCalib.Zelux

%%
close all
p.save()
