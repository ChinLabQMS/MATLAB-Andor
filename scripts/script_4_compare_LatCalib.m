%% Load calibration files, 1 is old, 2 is new
clear; clc; close all
calib1 = load("calibration/LatCalib_20241213.mat");
calib2 = load("calibration/LatCalib_20241218.mat");

%% Check the lattice calibrations of each camera, old
clc
calib1.Andor19330
calib1.Andor19331
calib1.Zelux

%% Check the lattice calibrations of each camera, new
clc
calib2.Andor19330
calib2.Andor19331
calib2.Zelux

%% Check the change in calibration for each camera
clc
Lattice.checkDiff(calib1.Andor19330, calib2.Andor19330)
Lattice.checkDiff(calib1.Andor19331, calib2.Andor19331)
Lattice.checkDiff(calib1.Zelux, calib2.Zelux)

%% Check the difference between upper and lower
clc
Lattice.checkDiff(calib1.Andor19330, calib1.Andor19331, 'Lower, old', 'Upper, old')
Lattice.checkDiff(calib2.Andor19330, calib2.Andor19331, 'Lower, new', 'Upper, new')
