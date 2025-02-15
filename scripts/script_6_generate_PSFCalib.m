%% Introduction
% Goal: Generate a file containing PSF calibration for different cameras. 

%% Create a PSFCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to lattice calibration file to use
% - PSFCalibFilePath: path to a pre-loaded PSF calibration file
% - DataPath: path to .mat data file for this calibration. PSF calibration 
%             should work in sparse settings
% - PSFCameraList: list of camera names for calibrating PSF
% - PSFImageLabel: corresponding list of image labels for PSF calibration

clear; clc; close all
p = PSFCalibrator( ...
    "DataPath", "data/2025/02 Feburary/20250213/sparse_14.mat", ...
    "PSFCameraList", ["Andor19330", "Andor19331"], ...
    "PSFImageLabel", ["Image", "Image"]);

%% Check signals, should be sparse
p.plotSignal()

%% Process single image, to check whether the filtering parameters are good
% Input format: 
%  - camera_name
%  - index_range (empty to process all shots)
%  - resolution_ratio, ratio of resolution to the ideal Rayleigh resolution,
%    when using a value larger than 1, it assumes a worse than ideal 
%    resolution when doing fit and filtering
%  - optional name-value pairs

close all
p.fit('Andor19330', 1, 1.3, 'plot_diagnostic', 1)
% p.PSFCalib.Andor19330.plotPSF()
p.PSFCalib.Andor19330

%% Andor19331
close all
p.fit('Andor19331', 1, 1.3, 'plot_diagnostic', 1)
% p.PSFCalib.Andor19331.plotPSF()
p.PSFCalib.Andor19331

%% Zelux
close all
p.fit('Zelux', 1, 4, 'plot_diagnostic', 1)
% p.PSFCalib.Zelux.plotPSF()
p.PSFCalib.Zelux

%% Process all data for Andor19330
close all
p.fit('Andor19330', [], 1.3, 'verbose', 1)
p.PSFCalib.Andor19330.plotWidthDist()
p.PSFCalib.Andor19330.plotPSF()
p.PSFCalib.Andor19330

%% Andor19331
close all
p.fit('Andor19331', [], 1.3, 'verbose', 1)
p.PSFCalib.Andor19331.plotWidthDist()
p.PSFCalib.Andor19331.plotPSF()
p.PSFCalib.Andor19331

%% Zelux
p.fit('Zelux', [], 4, 'refine_method', 'COM', 'filter_gausswid_max', inf, 'verbose', 1)
p.PSFCalib.Zelux.plotWidthDist()
p.PSFCalib.Zelux.plotPSF()
p.PSFCalib.Zelux

%% Check all cameras PSF
p.plotPSF()

%% Save the fitted PSF to a calibration file
% Default is "calibration/PSFCalib_<today's date>.mat"
% It will also update the default LatCalib file "calibration/LatCalib.mat"
close all
p.save()
