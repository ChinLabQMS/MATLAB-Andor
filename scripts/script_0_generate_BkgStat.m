%% Introduction
% Goal: Generate background calibration for different acqusition settings
% and different cameras. Faster readout tends to add more noise.
% The generated calibration file will be used in the Preprocessor to
% preprocess raw images.

%% Create a BkgStatGenerator object and configure file paths
% Configurable settings:
% - DataDir: path to folder that contains all data files
% - CameraList: list of cameras to calibrate background offset
% - ImageLabel: label of the background shot in the data for each camera
%               listed in CameraList
% - SettingList: list of settings to calibrate background offset, formated as
%                <Full/Cropped>_<Horizontal Readout speed>
% - xxx_xMHz: name of the data file that correspond to that settings

% Alternative to configure those settings upon object initiation, go to 
% "/core/preprocess/BkgStatGenerator" and edit the default settings

clear; clc; close all
p = BkgStatGenerator( ...
    "DataDir", "data/2024/09 September/20240926 camera readout noise/", ...
    "CameraList", ["Andor19330", "Andor19331"], ...
    "ImageLabel", ["Image", "Image"], ...
    "SettingList", ["Full_1MHz", "Full_3MHz", "Full_5MHz", "Cropped_1MHz", "Cropped_3MHz", "Cropped_5MHz"], ...
    "Full_1MHz", "clean_bg_1MHz.mat", ...
    "Cropped_1MHz", "clean_bg_1MHz_cropped.mat", ...
    "Full_3MHz", "clean_bg_3MHz.mat", ...
    "Cropped_3MHz", "clean_bg_3MHz_cropped.mat", ...
    "Full_5MHz", "clean_bg_5MHz.mat", ...
    "Cropped_5MHz", "clean_bg_5MHz_cropped.mat");
disp(p)

%% Process the data and generate background statistics
% Internally, it filters outliers, calculate mean images and performs
% Fourier filtering to obtain a smoothed mean

p.process()
disp(p.BkgSummary)

%% Plot some diagnostic figures to check if there is any residual pattern
p.plot("Full_1MHz", "Andor19330")

%% Save the background offset and noise calibration to file
p.save()

%% [IMPORTANT] Update the configuration in Preprocessor class definition 
% Don't forget to update the Preprocessor file here:
% "/core/preprocess/Preprocessor.m" to use the most recent calibration that 
% is just obtained!
