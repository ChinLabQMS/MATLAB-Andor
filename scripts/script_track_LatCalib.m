%% Create a Calibrator object
clear; clc; close all
p = LatCalibrator;

%% Config DataPath

p.config("DataPath", "data/2024/10 October/20241021 DMD alignment/BIG300_anchor=64_array64_spacing=100_centered_r=20_r=10.mat")

%%
res = p.trackCalib();

%%
errorbar(res.Andor19330.R1, res.Andor19330.R1_Std)
yyaxis right
errorbar(res.Andor19330.R2, res.Andor19330.R2_Std)
xlabel("Run Number")
grid on

%%
errorbar(res.Andor19331.R1, res.Andor19331.R1_Std)
yyaxis right
errorbar(res.Andor19331.R2, res.Andor19331.R2_Std)
grid on

%%
LatAndor19330 = p.LatCalib.Andor19330;
LatAndor19331 = p.LatCalib.Andor19331;
LatZelux = p.LatCalib.Zelux;

R1_Andor19330 = res.Andor19330.R1;
R2_Andor19330 = res.Andor19330.R2;
R1Std_Andor19330 = res.Andor19330.R1_Std;
R2Std_Andor19330 = res.Andor19331.R2_Std;

R_Andor19331 = LatAndor19331.transform(LatAndor19330, [res.Andor19331.R1, res.Andor19331.R2], "round_output", false);
R1_Andor19331 = R_Andor19331(:, 1);
R2_Andor19331 = R_Andor19331(:, 2);

R_Zelux = LatZelux.transform(LatAndor19330, [res.Zelux.R1, res.Zelux.R2], "round_output", false);
R1_Zelux = R_Zelux(:, 1);
R2_Zelux = R_Zelux(:, 2);

%%
errorbar(R1_Andor19330, R1Std_Andor19330)
yyaxis right
plot(R1_Zelux)
