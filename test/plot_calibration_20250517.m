%% Plot calibration
clear; clc; close all
p = Preprocessor();

Data = load('data/2025/04 April/20250416/dense_calibration.mat').Data;
Signal = p.process(Data);
pattern_532 = Signal.Zelux.Pattern_532;
lattice_935 = Signal.Zelux.Lattice_935;
atom = Signal.Andor19331.Image;

grid = SiteGrid("SiteFormat", "Hex", "HexRadius", 8);
counter = SiteCounter("Andor19331", [], [], grid);
counter.Lattice.init([240, 620], 'format', 'R_only')

[upper_box, upper_x, upper_y] = prepareBox(atom(:,:,1), counter.Lattice.R, 70);
counter.Lattice.calibrateR(upper_box, upper_x, upper_y)

zelux = load('calibration/LatCalib.mat').Zelux;
zelux.init([750, 400], 'format', 'R_only')

%%
pattern = mean(pattern_532, 3);
[pattern_box, pattern_x, pattern_y] = prepareBox(pattern, zelux.R, 300);

figure
imagesc(pattern_y, pattern_x, pattern_box)
daspect([1 1 1])
xticks([])
yticks([])
zelux.plotV('add_legend', false, 'scale', 5, 'color1', 'k', 'color2', 'r')

%%
pattern_upper = zelux.transformSignal(counter.Lattice, upper_x, upper_y, pattern_box, pattern_x, pattern_y);

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
imagesc(mean(lattice_935, 3))
daspect([1 1 1])
xticks([])
yticks([])