%% Plot pictures of poked lattice sites
clear; clc; close all
p = Preprocessor();

% DataPath = "data/2025/06 June/20250603/prep8_LS_off_Sprout=2.5V_rampdown_sites_step=5_r=5.mat";
% PatternPath = "data/2025/06 June/20250603/template/circle_array_python_r=5_step=5_inverted.bmp";
% LatCalibFilePath = "calibration/dated_LatCalib/LatCalib_20250603.mat";

DataPath = "data\2025\06 June\20250603\prep8_LS_off_mod=2ms_Sprout=2.5V_rampdown_sites_step=5_r=5.mat";
PatternPath = "data\2025\06 June\20250603\template\circle_array_python_r=5_step=5_inverted.bmp";
LatCalibFilePath = "calibration\dated_LatCalib\LatCalib_20250603.mat";

%%
Data = load(DataPath).Data; 
load(LatCalibFilePath); 
template = imread(PatternPath);

Signal = p.process(Data);
pattern_532 = Signal.Zelux.Pattern_532;
lattice_935 = Signal.Zelux.Lattice_935;
upper_signal = Signal.Andor19331.Image;
mean_upper = mean(upper_signal, 3);

grid = SiteGrid("SiteFormat", "Hex", "HexRadius", 20);
counter = SiteCounter("Andor19331", Andor19331, [], grid);

[upper_box, upper_x, upper_y] = prepareBox(upper_signal(:,:,1), round(counter.Lattice.R), 125); % rounding it fixed the bug
counter.Lattice.calibrateR(upper_box, upper_x, upper_y)

transformed_template = DMD.transformSignal(Andor19331, upper_x, upper_y, template);
transformed_pattern = Zelux.transformSignal(Andor19331, upper_x, upper_y, template);

%%
figure;
imagesc(upper_signal(:,:,1));
daspect([1 1 1])
colorbar

%%
stat = counter.process(upper_signal, 2, "calib_mode",'offset','classify_method','fixed','fixed_thresholds',450);

figure
histogram(stat.LatCount)

%%
prob = mean(stat.LatOccup, 3);
prob = prob(:, 2);

figure
counter.Lattice.plotCounts(stat.SiteInfo.Sites, prob)
counter.Lattice.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
    'norm_radius', 1.5, 'diff_origin', 0,'Color','w')
xlim([upper_y(1), upper_y(end)])
ylim([upper_x(1), upper_x(end)])
xticks([])
yticks([])
cb = colorbar;
cb.FontSize = 16;
%%
h=counter.Lattice.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
    'norm_radius', 1.5, 'diff_origin', 0,'Color','w');
disp(h)
children = get(h,'Children');
set(children,'LineWidth',2)
%% making the figure have 4 panels, also make the overlaid lattice bolder

figure('Units','inches','Position', [1,1,8,3]);
subplot(1, 4, 3)
imagesc(upper_y, upper_x, upper_signal(upper_x + 512, upper_y, 6)) % was 9
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
Andor19331.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
                'norm_radius', 1.5, 'diff_origin', 0, 'center', Andor19331.R,'Color','w')
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 4, 2)
imagesc(upper_y, upper_x, mean_upper(upper_x, upper_y))
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
Andor19331.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
                'norm_radius', 1.5, 'diff_origin', 0, 'center', Andor19331.R,'Color','w')
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 4, 1)
imagesc(upper_y, upper_x, transformed_template)
daspect([1 1 1])
xticks([])
yticks([])
colormap(gca(), 'gray')

subplot(1,4,4)
counter.Lattice.plotCounts(stat.SiteInfo.Sites, prob)
counter.Lattice.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
    'norm_radius', 1.5, 'diff_origin', 0,'Color','w')
xlim([upper_y(1), upper_y(end)])
ylim([upper_x(1), upper_x(end)])
xticks([])
yticks([])
daspect([1 1 1])
cb = colorbar('Position',[0.92 0.11 0.015 0.77]);
cb.FontSize = 10;

%% if fig just has 3 panels
figure('Units','inches','Position', [1,1,8,3]);
subplot(1, 3, 3)
imagesc(upper_y, upper_x, upper_signal(upper_x + 512, upper_y, 6)) % was 9
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
Andor19331.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
                'norm_radius', 1.5, 'diff_origin', 0, 'center', Andor19331.R,'Color','w')
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 3, 2)
imagesc(upper_y, upper_x, mean_upper(upper_x, upper_y))
daspect([1 1 1])
xticks([])
yticks([])
clim([0, inf])
Andor19331.plot(SiteGrid.prepareSite('Hex', 'latr', 20, 'latr_step', 5), ...
                'norm_radius', 1.5, 'diff_origin', 0, 'center', Andor19331.R,'Color','w')
line([upper_y(1) + 10, upper_y(1) + 10 + 33.63], ...
     [upper_x(end) - 10, upper_x(end) - 10], ...
    'Color', 'w', 'LineWidth', 5)

subplot(1, 3, 1)
imagesc(upper_y, upper_x, transformed_template)
daspect([1 1 1])
xticks([])
yticks([])
colormap(gca(), 'gray')

exportgraphics(gcf,'damop2025keep1.pdf','ContentType','vector')

%%
dmd = Projector();
dmd.open()

live.LatCalib = load("calibration/LatCalib.mat");
live.Temporary.Andor19330.Image.SiteStat = stat;
live.Temporary.Andor19330.Image.SiteStat.LatOccup = stat.LatOccup(:, 2, 10);

%%
dmd.project(live, 'mode', "BlackTweezersDynamic", "black_tweezer_radius", 100, "tweezer_shift", [10, 10], "pattern_delay", 1000)
