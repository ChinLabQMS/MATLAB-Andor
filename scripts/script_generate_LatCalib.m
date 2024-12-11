%% Create a Calibrator object
clear; clc; close all
p = LatCalibrator( ...
    "LatCalibFilePath", [], ... 
    "DataPath", "data/2024/12 December/20241205/sparse_with_532_r=2.mat");

%% Andor19330: Plot FFT of a small box centered at atom cloud
close all
p.plotFFT("Andor19330_852")

%% Andor19330: Input center of lattice and initial peak positions as [x1, y1; x2, y2]
% Select the first and second peaks to the right, clockwise from 12 o'clock
close all
p.calibrate("Andor19330_852", [122, 236; 181, 279])

%% Andor19331
close all
p.plotFFT("Andor19331_852")

%% Andor19331: Input the peaks that corresponds to the Andor19330 peaks under its coordinates
% Select the second and first peaks to the right, clockwise
close all
p.calibrate("Andor19331_852", [167, 271; 123, 207])

%% Zelux
close all
p.plotFFT("Zelux_935")

%% Input the peaks positions in the orientation similar to Andor19330
close all
p.calibrate("Zelux_935", [654, 565; 714, 595])

%% Cross-calibrate Andor19331 to Andor19330
close all
p.calibrateO(1, 'sites', Lattice.prepareSite('hex', 'latr', 20))

%% (optional) Calibrate to a different signal index by searching a smaller region
p.calibrateO(20, 'sites', Lattice.prepareSite('hex', 'latr', 2))

%% Save lattice calibration of all three cameras (default is with today's date)
p.save()
