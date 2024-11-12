%% Create a Calibrator object
clear; clc; close all
p = LatCalibrator("DataPath", ...
    "data/2024/11 November/20241106/BIG_data_exp=1.2s.mat");
    % "data/2024/10 October/20241021 DMD alignment/BIG300_anchor=64_array64_spacing=100_centered_r=20_r=10.mat");
    % "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat");

%% Generate drift report table
res = p.trackCalib();

%% Track drift in lattice frame over time

ref_index = 10;

figure
subplot(2, 1, 1)
errorbar(res.Andor19330.LatR1 - res.Andor19330.LatR1(ref_index) - 2, res.Andor19330.LatR1_Std)
hold on
errorbar(res.Andor19331.LatR1 - res.Andor19331.LatR1(ref_index), res.Andor19331.LatR1_Std)
errorbar(res.Zelux.LatR1 - res.Zelux.LatR1(ref_index) - 1, res.Zelux.LatR1_Std)
xlabel("Run Number")
grid on
legend(["Andor19330", "Andor19331", "Zelux"], "Location", "eastoutside")
ylabel('LatR1')

subplot(2, 1, 2)
errorbar(res.Andor19330.LatR2 - res.Andor19330.LatR2(ref_index) - 2, res.Andor19330.LatR2_Std)
hold on
errorbar(res.Andor19331.LatR2 - res.Andor19331.LatR2(ref_index), res.Andor19331.LatR2_Std)
errorbar(res.Zelux.LatR2 - res.Zelux.LatR2(ref_index) - 1, res.Zelux.LatR2_Std)
xlabel("Run Number")
grid on
legend(["Andor19330", "Andor19331", "Zelux"], "Location", "eastoutside")
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

%% Make a GIF

start_idx = 60;
end_idx = 80;

