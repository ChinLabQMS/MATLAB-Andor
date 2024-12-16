%% Introduction
% Goal: Generate a file containing PSF calibration for different cameras. 
% PSF calibrations are labeled as '<camera_name>_<imaging_wavelength>' 
% which not only includes the camera name but also the imaging wavelength, 
% because at different wavelengths the diffraction-limited resolution is 
% different, to accurately compare the measured PSF to diffraction limit, 
% it has to include the imaging wavelength information.

%% Create a PSFCalibrator object
% Configurable settings:
% - LatCalibFilePath: 
% - DataPath: 
% - PSFCameraList: list of camera names for calibrating PSF
% - PSFImageLabel: corresponding list of image labels for PSF calibration

clear; clc; close all

