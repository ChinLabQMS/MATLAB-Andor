%% Create a Calibrator object
clear; clc;
p = LatCaliberator;

%% Pre-calibration, with no existing calibration file

% Config data path
% - for initial calibration, set LatCalibFilePath to []
p.config( ...
    "LatCalibFilePath", [], ... 
    "DataPath", "data/2024/09 September/20240930 multilayer/FK2_focused_to_major_layer.mat")

% Process the data
% - pre-process to remove offset and outliers, get fitted centers and FFT patterns, etc.
p.process()

%% Andor19330: Plot FFT of a small box centered at atom cloud
close all
p.plot("Andor19330")

%% Andor19330: Input initial peak positions as [x1, y1; x2, y2], at least two peaks
close all
p.calibrate("Andor19330", [105, 204; 156, 242])

%% Andor19331
close all
p.plot("Andor19331")

%% Andor19331: Input the peaks that corresponds to the Andor19330 peaks under its coordinates
close all
p.calibrate("Andor19331", [155, 216; 116, 165])

%% Zelux
close all
p.plot("Zelux")

%% Input the peaks positions in the orientation similar to Andor19330
close all
p.calibrate("Zelux", [656, 566; 716, 595])

%% Cross-calibrate Andor19331 to Andor19330


%% Save lattice calibration of all three cameras (default is with today's date)
p.save()

%% Re-calibrate the lattice to a new dataset

% Set an initial calibration file location and new data location for re-calibration
p.config( ...
    "LatCalibFilePath", "calibration/LatCalib_20241002.mat", ... 
    "DataPath", "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat")
p.recalibrate()

%% Save re-calibration result (default is with today's date)
close all
p.save()
