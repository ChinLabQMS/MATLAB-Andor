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

%% Histograms

bins = linspace(-0.3, 0.3, 30);

figure
val = res.Andor19330.LatR1 - res.Andor19330.LatR1(ref_index);
subplot(4, 2, 1)
histogram(val, "BinEdges", bins)
title(sprintf("Andor19330 LatR1, std: %g", std(val)))

subplot(4, 2, 2)
val = res.Andor19330.LatR2 - res.Andor19330.LatR2(ref_index);
histogram(val, "BinEdges", bins)
title(sprintf("Andor19330 LatR2, std: %g", std(val)))

subplot(4, 2, 3)
val = res.Andor19331.LatR1 - res.Andor19331.LatR1(ref_index);
histogram(val, "BinEdges", bins)
title(sprintf("Andor19331 LatR1, std: %g", std(val)))

subplot(4, 2, 4)
val = res.Andor19331.LatR2 - res.Andor19331.LatR2(ref_index);
histogram(val, "BinEdges", bins)
title(sprintf("Andor19331 LatR2, std: %g", std(val)))

subplot(4, 2, 5)
val = res.Zelux.LatR1 - res.Zelux.LatR1(ref_index);
histogram(val, "BinEdges", bins)
title("Zelux LatR1")

subplot(4, 2, 6)
val = res.Zelux.LatR2 - res.Zelux.LatR2(ref_index);
histogram(val, "BinEdges", bins)
title(sprintf("Zelux LatR1, std: %g", std(val)))

subplot(4, 2, 7)
val = (res.Andor19330.LatR1 - res.Andor19330.LatR1(ref_index)) - ...
    (res.Zelux.LatR1 - res.Zelux.LatR1(ref_index));
histogram(val, "BinEdges", bins)
title(sprintf("(Andor19330 - Zelux) LatR1, std: %g", std(val)))

subplot(4, 2, 8)
val = (res.Andor19330.LatR2 - res.Andor19330.LatR2(ref_index)) - ...
    (res.Zelux.LatR2 - res.Zelux.LatR2(ref_index));
histogram(val, "BinEdges", bins)
title(sprintf("(Andor19330 - Zelux) LatR2, std: %g", std(val)))

%% Correlation analysis

x1 = res.Zelux.LatR1;
x2 = res.Zelux.LatR2;
y1 = res.Andor19330.LatR1;
y2 = res.Andor19330.LatR2;

figure
subplot(1, 2, 1)
scatter(x1, y1)
daspect([1 1 1])
xlabel('Zelux LatR1')
ylabel('Andor19330 LatR1')
title(sprintf('Corr: %g', corr(x1, y1)))

subplot(1, 2, 2)
scatter(x2, y2)
daspect([1 1 1])
xlabel('Zelux LatR2')
ylabel('Andor19330 LatR2')
title(sprintf('Corr: %g', corr(x2, y2)))
