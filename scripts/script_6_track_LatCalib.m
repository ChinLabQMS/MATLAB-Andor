%% Introduction
% Goal: Track the calibration drifts over time on different
% cameras and projectors

%% Create a Calibrator object
clear; clc; close all
p = CombinedCalibrator( ...
    "DataPath", "data/2025/03 March/20250311 big dataset to track drift/dense_big.mat");
    % "DataPath", "data/2024/12 December/20241205/sparse_with_532_r=2_big.mat");

%% Generate drift report table
% Lattice phase shift
res = p.trackLat();

%% Zelux PSF shift drift report
res.ZeluxPSF = p.trackPSF();

%% Track drift in lattice frame over time

names = ["Andor19331", "Andor19330", "Zelux", "ZeluxPSF"];
shiftv = [0, -1, -2, -3];  % offset on the line plots

ref_index = 10;

figure
subplot(2, 1, 1)
hold on
for i = 1: length(names)
    name = names(i);
    val = res.(name).LatR1 - res.(name).LatR1(ref_index) + shiftv(i);
    errorbar(val, res.(name).LatR1_Std)
end
xlabel("Run Number")
grid on
legend(names, 'Location', 'eastoutside', 'Interpreter', 'none')
ylabel('LatR1')

subplot(2, 1, 2)
hold on
for i = 1: length(names)
    name = names(i);
    val = res.(name).LatR2 - res.(name).LatR2(ref_index) + shiftv(i);
    errorbar(val, res.(name).LatR2_Std)
end
xlabel("Run Number")
grid on
legend(names, 'Location', 'eastoutside', 'Interpreter', 'none')
ylabel('LatR2')

%% Correlation analysis

Var1 = "ZeluxPSF";
Var2 = "Andor19330";

x1 = res.(Var1).LatR1;
x2 = res.(Var1).LatR2;
y1 = res.(Var2).LatR1;
y2 = res.(Var2).LatR2;

figure
subplot(1, 2, 1)
scatter(x1, y1)
daspect([1 1 1])
xlabel(Var1 + " LatR1")
ylabel(Var2 + " LatR1")

subplot(1, 2, 2)
scatter(x2, y2)
daspect([1 1 1])
xlabel(Var1 + " LatR2")
ylabel(Var2 + " LatR2")
