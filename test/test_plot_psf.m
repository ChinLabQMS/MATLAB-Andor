% data_dir = 'data/2023/11 November/2023-11-02/converted/';
% data_dir = 'data/2023/11 November/2023-11-16/converted/';
data_dir = 'data/OLD Data/Objective PSF data/';

p = Preprocessor();

%%
filename = '201028_dmd_after_upper_obj_tweak.asc';
% filename = 'ResolutionAfter.asc';
% filename = 'dots_r=2_spacing_100_upper_right3.asc';
% filename = 'dots_r=1_spacing=100_final.asc';
% filename = 'lattice_final_bottom.asc';

data = flip(transpose(readmatrix(fullfile(data_dir, filename))), 1);
data = data(1:end - 1, :);

config.Cropped = false;
config.HSSpeed = 2;
config.NumSubFrames = 1;

%%
data = Data.Img(:,:,1);

config.Cropped = false;
config.HSSpeed = 2;
config.NumSubFrames = 8;

%%
signal = p.process(data, 'camera', 'Andor19330', 'label', 'Image', 'config', config);

figure
imagesc2(signal)

%%
f = fitGauss2D(signal);

%%
ps = PointSource();
ps.setRatio(3)
ps.fit(signal, 'plot_diagnostic', 1, 'bin_threshold_max', 200)

ps.plotPSF()

%%
figure
ps.plot()
xticks([])
yticks([])
% xlim([-15, 30])
% ylim([-30, 15])
% line([-11.8, 0], [10, 10], 'Color', 'w', 'LineWidth', 6)

xlim([-25, 20])
ylim([-15, 30])
line([-21.8, -10], [25, 25], 'Color', 'w', 'LineWidth', 6)

% xlim([-22, 22])
% ylim([-22, 22])
% line([-18.8, -7], [17, 17], 'Color', 'w', 'LineWidth', 6)
% cb = colorbar();
% cb.Ticks = [];

%%
clc
f = 90;
% data_path = 'data/2024/02 February/2024-02-12 lattice trap freq/atomnum_200khz.csv';
data_path = sprintf('data/2024/02 February/2024-02-13/%dkhz_xwidth_ls.csv', f);

data = readmatrix(data_path);
disp(mean(data(:, 2), 'omitnan'))
disp(std(data(:, 2), 'omitnan'))

%%
data_path = 'data/2024/02 February/2024-02-12 lattice trap freq/lattice_trap_freq.csv';
data = readmatrix(data_path);

figure('Position', [300, 500, 800, 400])
errorbar(data(:, 1), data(:, 2), data(:, 3), 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Modulation frequency (kHz)', 'FontSize', 14)
ylabel('Atom number', 'FontSize', 14)
ax = gca;
ax.FontSize = 14;
xlim([20, 210])

%%
data = [99, 40;
        116, 41.25;
        150, 47.5];
figure
errorbar(data(:, 1), data(:, 2), [5; 5; 5], 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Single lattice beam power (mW)', 'FontSize', 14)
ylabel('Trap frequency (kHz)', 'FontSize', 14)
ax = gca;
xlim([0, 370])
ylim([0, 80])
ax.FontSize = 14;
hold on
fplot(@(x) 3.88*sqrt(x), 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
scatter(350, 3.88*sqrt(350), 100, 'filled', 'diamond', 'MarkerEdgeColor', 'k', 'LineWidth', 1)

%%
data = [1.57, 11.25;
        2.89, 15.75;
        4.45, 18];
figure
errorbar(data(:, 1), data(:, 2), [2; 2; 2], 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Light sheet beam power (W)', 'FontSize', 14)
ylabel('Trap frequency (kHz)', 'FontSize', 14)
ax = gca;
xlim([0, 5])
ylim([0, 25])
ax.FontSize = 14;
hold on
fplot(@(x) 8.83*sqrt(x), 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
scatter(2.7, 8.83*sqrt(2.7), 100, 'filled', 'diamond', 'MarkerEdgeColor', 'k', 'LineWidth', 1)

%%
data_path = 'data/2024/02 February/2024-02-13/light_sheet.csv';
data = readmatrix(data_path);

figure('Position', [300, 500, 800, 400])
errorbar(data(:, 1), data(:, 2), data(:, 3), 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Modulation frequency (kHz)', 'FontSize', 14)
ylabel('Atom number', 'FontSize', 14)
ax = gca;
ax.FontSize = 14;

