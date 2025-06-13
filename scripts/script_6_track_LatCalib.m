%% Introduction
% Goal: Track the calibration drifts over time on different
% cameras and projectors

%% Create a Calibrator object
clear; clc; close all
p = CombinedCalibrator( ...
    "LatCalibFilePath", "calibration/dated_LatCalib/LatCalib_20250321.mat", ...
    "DataPath", "data/2025/03 March/20250311 big dataset to track drift/dense_big.mat");
    % "DataPath", "data/2024/12 December/20241205/sparse_with_532_r=2_big.mat");

%% Generate drift report table by calibrating lattice phases
% Lattice phase shift
res = p.trackLat();

%% Zelux PSF shift drift report
res.ZeluxPSF = p.trackPeaks();

%%
for dev = string(fields(res))'
    if ismember(dev, ["Andor19330", "Andor19331", "Zelux"])
        R = [res.(dev).R1_Sub(:), res.(dev).R2_Sub(:)];
        NormR = R / p.LatCalib.(dev).V * [0, 1; -1/2*sqrt(3), -1/2];
        NormR1 = reshape(NormR(:, 1), [], 4);
        NormR2 = reshape(NormR(:, 2), [], 4);
    else
        R = [res.(dev).R1_Peak(:), res.(dev).R2_Peak(:)];
        NormR = R / p.LatCalib.Zelux.V * [0, 1; -1/2*sqrt(3), -1/2];
        NormR1 = reshape(NormR(:, 1), [], 10);
        NormR2 = reshape(NormR(:, 2), [], 10);
    end
    res.(dev).NormR1 = mean(NormR1, 2);
    res.(dev).NormR2 = mean(NormR2, 2);
    res.(dev).NormR1_Std = std(NormR1, 0, 2);
    res.(dev).NormR2_Std = std(NormR2, 0, 2);
end

%% Track drift in lattice frame over time

names = ["Andor19331", "Andor19330", "Zelux", "ZeluxPSF"];
legends = ["Upper CCD (lattice)", "Lower CCD (lattice)", "Zelux (lattice)", "Zelux (tweezer)"];
shiftv = [0, -1, -2, -3];  % offset on the line plots

ref_index = 10;

figure("Position",[50, 50, 1200, 1000])
subplot(2, 1, 1)
hold on
for i = 1: length(names)
    name = names(i);
    % val = res.(name).LatR1 - res.(name).LatR1(ref_index) + shiftv(i);
    val = res.(name).NormR1 - res.(name).NormR1(ref_index) + shiftv(i);
    errorbar(val, res.(name).LatR1_Std)
end
xlabel("run number", 'FontSize', 16)
grid on
box on
legend(legends, 'Location', 'eastoutside', 'Interpreter', 'none', 'FontSize', 16)
ylabel('drift x (site)', 'FontSize', 16)
ax = gca();
ax.FontSize = 16;

subplot(2, 1, 2)
hold on
for i = 1: length(names)
    name = names(i);
    % val = res.(name).LatR2 - res.(name).LatR2(ref_index) + shiftv(i);
    val = res.(name).NormR2 - res.(name).NormR2(ref_index) + shiftv(i);
    errorbar(val, res.(name).LatR2_Std)
end
xlabel("run number")
grid on
box on
legend(legends, 'Location', 'eastoutside', 'Interpreter', 'none', 'FontSize', 16)
ylabel('drift y (site)', 'FontSize', 16)
ax = gca();
ax.FontSize = 16;

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
