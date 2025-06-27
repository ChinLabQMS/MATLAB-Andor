%% Plot pictures of poked lattice sites
clear; clc; close all
p = Preprocessor();


% DataPath = "data/2025/05 May/20250521/v2_every_5_sites.mat";
% PatternPath = "data/2025/05 May/20250521/template/V1=[-3.31, 10.25]_V2=[-7.16, -7.78]_offset=[-15, -10, -5, 0, 5, 10, 15]_width=5.bmp";
DataPath = "data/2025/05 May/20250521/spots_r=5_step=5.mat";
PatternPath = "data/2025/05 May/20250521/template/circle_array_python_r=5_step=5.bmp";
% DataPath = "data/2025/05 May/20250521/pattern_O.mat";
% PatternPath = "data/2025/05 May/20250521/template/pattern_O.bmp";
LatCalibFilePath = "calibration/dated_LatCalib/LatCalib_20250521_221021.mat";

Data = load(DataPath).Data; 
load(LatCalibFilePath); 
template = imread(PatternPath);

Signal = p.process(Data);
pattern_532 = Signal.Zelux.Pattern_532;
lattice_935 = Signal.Zelux.Lattice_935;
upper_signal = Signal.Andor19331.Image;
mean_upper = mean(upper_signal, 3);

grid = SiteGrid("SiteFormat", "Hex", "HexRadius", 8);
counter = SiteCounter("Andor19331", Andor19331, [], grid);

[upper_box, upper_x, upper_y] = prepareBox(upper_signal(:,:,1), round(counter.Lattice.R), 100);
counter.Lattice.calibrateR(upper_box, upper_x, upper_y)

transformed_pattern = DMD.transformSignal(Andor19331, upper_x, upper_y, template);

%%
figure('Units','inches','Position', [1,1,8,3]);
subplot(1, 3, 3)
imagesc(upper_y, upper_x, upper_box)
% h = counter.Lattice.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
%     'norm_radius', 0.5, 'diff_origin', 0,'Color','w');
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 3, 2)
imagesc(upper_y, upper_x, mean_upper(upper_x, upper_y))
%counter.Lattice.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
%    'norm_radius', 0.5, 'diff_origin', 0,'Color','w')
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 3, 1)
imagesc(upper_y, upper_x, transformed_pattern)
daspect([1 1 1])
xticks([])
yticks([])
colormap(gca(), 'gray')

%%
exportgraphics(gcf,'damop2025pokeholes1.pdf','ContentType','vector')