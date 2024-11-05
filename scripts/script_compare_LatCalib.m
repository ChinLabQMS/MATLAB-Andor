%% Load calibration files
clear; clc; close all
calib1 = load("calibration/LatCalib_20241028.mat");
calib2 = load("calibration/LatCalib_20241104.mat");

%%
Lattice.checkDiff(calib1.Andor19330, calib2.Andor19330)
Lattice.checkDiff(calib1.Andor19331, calib2.Andor19331)
Lattice.checkDiff(calib1.Zelux, calib2.Zelux)
