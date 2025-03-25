%% Load calibration files, 1 is old, 2 is new
clear; clc; close all
calib1 = load("calibration/dated_LatCalib/LatCalib_20250225.mat");
calib2 = load("calibration/dated_LatCalib/LatCalib_20250324.mat");

%% Check the lattice calibrations of each camera, old
clc
calib1.Andor19330
calib1.Andor19331
calib1.Zelux
calib1.DMD

%% Check the lattice calibrations of each camera, new
clc
calib2.Andor19330
calib2.Andor19331
calib2.Zelux
calib2.DMD

%% Check the change in calibration for each camera
clc
Lattice.checkDiff(calib1.Andor19330, calib2.Andor19330)
Lattice.checkDiff(calib1.Andor19331, calib2.Andor19331)
Lattice.checkDiff(calib1.Zelux, calib2.Zelux)
Lattice.checkDiff(calib1.DMD, calib2.DMD)

%% Check the difference between upper and lower
clc
Lattice.checkDiff(calib1.Andor19330, calib1.Andor19331, 'Lower, old', 'Upper, old')
Lattice.checkDiff(calib2.Andor19330, calib2.Andor19331, 'Lower, new', 'Upper, new')
