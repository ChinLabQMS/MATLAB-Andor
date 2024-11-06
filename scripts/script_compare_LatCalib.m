%% Load calibration files
clear; clc; close all
calib1 = load("calibration/LatCalib_20241104.mat");
calib2 = load("calibration/LatCalib_20241105.mat");

%% Check the change in calibration for each camera
Lattice.checkDiff(calib1.Andor19330, calib2.Andor19330)
Lattice.checkDiff(calib1.Andor19331, calib2.Andor19331)
Lattice.checkDiff(calib1.Zelux, calib2.Zelux)

%% Check the difference between upper and lower CCD
Lattice.checkDiff(calib1.Andor19330, calib1.Andor19331, ' (Lower, old)', ' (Upper, old)')
Lattice.checkDiff(calib2.Andor19330, calib2.Andor19331, ' (Lower, new)', ' (Upper, new)')
