%% Plot figures for illustrating calibration process
clear; clc; close all
p = Preprocessor();

DataPath = "data/2025/06 June/20250602/cal3.mat";
LatCalibFilePath = "calibration/dated_LatCalib/LatCalib_20250602_150358.mat";

Data = load(DataPath).Data;
load(LatCalibFilePath);

Signal = p.process(Data);
pattern_532 = Signal.Zelux.Pattern_532;
lattice_935 = Signal.Zelux.Lattice_935;
atom = Signal.Andor19331.Image;

grid = SiteGrid("SiteFormat", "Hex", "HexRadius", 8);
counter = SiteCounter("Andor19331", Andor19331, [], grid);
counter.Lattice.init([255, 620], 'format', 'R')

[upper_box, upper_x, upper_y] = prepareBox(atom(:,:,1), counter.Lattice.R, 70);
counter.Lattice.calibrateR(upper_box, upper_x, upper_y)

Zelux.init([775, 555], 'format', 'R')

%%
pattern = mean(pattern_532, 3);
[pattern_box, pattern_x, pattern_y] = prepareBox(pattern, Zelux.R, 300);

figure
imagesc(pattern_y, pattern_x, pattern_box)
daspect([1 1 1])
xticks([])
yticks([])
Zelux.plotV('add_legend', false, 'scale', 5, 'color1', 'k', 'color2', 'r')

%%
pattern_upper = Zelux.transformSignal(counter.Lattice, upper_x, upper_y, pattern_box, pattern_x, pattern_y);

figure
imagesc(upper_y, upper_x, pattern_upper)
daspect([1 1 1])
xticks([])
yticks([])
counter.Lattice.plotV('add_legend', false, 'scale', 5, 'color1', 'k', 'color2', 'r')

%%
figure
imagesc(upper_y, upper_x, mean(atom(upper_x, upper_y, :), 3))
daspect([1 1 1])
xticks([])
yticks([])
clim([20, inf])
counter.Lattice.plotV('add_legend', false, 'scale', 5, 'color1', 'k', 'color2', 'r')

%%
figure
imagesc(upper_y, upper_x, atom(upper_x, upper_y, 1))
daspect([1 1 1])
xticks([])
yticks([])
clim([20, inf])
counter.Lattice.plotV('add_legend', false, 'scale', 5, 'color1', 'k', 'color2', 'r')

%% Illustrate cross-calibration
p = LatCalibrator( ...
    "LatCalibFilePath", LatCalibFilePath, ... 
    "DataPath", DataPath, ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"], ...
    "ProjectorList", "DMD");
p.LatCalib.Zelux.init([775, 555], 'format', 'R')
p.LatCalib.Andor19331.init([255, 620], 'format', 'R')

p.recalibrate( ...
    "reset_centers", 0, ...
    "calibO", 1, "signal_index", 1, "sites", SiteGrid.prepareSite('Hex', 'latr', 20), ... % Specify the shot index for cross calibration
    "plot_diagnosticV", 0, ...
    "plot_diagnosticR", 0, ...
    "plot_diagnosticO", 0)

%%
% p.calibrateProjector('sites', SiteGrid.prepareSite('Hex', 'latr', 10), 'debug', true)
p.calibrateProjector('sites', SiteGrid.prepareSite('Hex', 'latr', 10), 'debug', false)
p.calibrateProjector('sites', SiteGrid.prepareSite('Hex', 'latr', 3, 'latr_step', 0.1), 'debug', true)

%%
ax = gca();
ax.XLim = [pattern_y(1), pattern_y(end)];
ax.YLim = [pattern_x(1), pattern_x(end)];
ax.Title.String = "";
ax.XTick = [];
ax.YTick = [];

%%
figure
imagesc(mean(lattice_935, 3))
daspect([1 1 1])
xticks([])
yticks([])
