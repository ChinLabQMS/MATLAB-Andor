%% Create a Calibrator object
clear; clc; close all
p = LatCalibrator;

%% Config DataPath

p.config("DataPath", "data/2024/10 October/20241021 DMD alignment/BIG300_anchor=64_array64_spacing=100_centered_r=20_r=10.mat")

%% Generate drift report table
res = p.trackCalib();

%% Track drift in lattice frame over time

ref_index = 5;

figure
subplot(2, 1, 1)
errorbar(res.Andor19330.LatR1 - res.Andor19330.LatR1(ref_index) - 2, res.Andor19330.LatR1_Std)
hold on
errorbar(res.Andor19331.LatR1 - res.Andor19331.LatR1(ref_index), res.Andor19331.LatR1_Std)
errorbar(res.Zelux.LatR1 - res.Zelux.LatR1(ref_index) - 1, res.Zelux.LatR1_Std)
xlabel("Run Number")
grid on
legend(["Andor19330", "Andor19331", "Zelux"])

subplot(2, 1, 2)
errorbar(res.Andor19330.LatR2 - res.Andor19330.LatR2(ref_index) - 2, res.Andor19330.LatR2_Std)
hold on
errorbar(res.Andor19331.LatR2 - res.Andor19331.LatR2(ref_index), res.Andor19331.LatR2_Std)
errorbar(res.Zelux.LatR2 - res.Zelux.LatR2(ref_index) - 1, res.Zelux.LatR2_Std)
xlabel("Run Number")
grid on
legend(["Andor19330", "Andor19331", "Zelux"])

%% Correlation analysis


