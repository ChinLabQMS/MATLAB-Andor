%% Introduction
% Goal: Track the lattice calibration drifts over time on different cameras

%% Create a Calibrator object
clear; clc; close all
p = LatCalibrator( ...
    "DataPath", "data/2025/03 March/20250310 debugging/30min_data.mat");
    % "DataPath", "data/2024/12 December/20241205/sparse_with_532_r=2_big.mat");

%% Generate drift report table
res = p.trackCalib();

%% Track drift in lattice frame over time

names = ["Andor19331", "Andor19330", "Zelux"];
shiftv = [0, -1, -2];  % offset on the line plots

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

x1 = res.Zelux.LatR1;
x2 = res.Zelux.LatR2;
y1 = res.Andor19330.LatR1;
y2 = res.Andor19330.LatR2;

figure
subplot(1, 2, 1)
scatter(x1, y1)
xlabel('Andor19330 LatR1')
ylabel('Zelux LatR1')

subplot(1, 2, 2)
scatter(x2, y2)
xlabel('Andor19330 LatR2')
ylabel('Zelux LatR2')
