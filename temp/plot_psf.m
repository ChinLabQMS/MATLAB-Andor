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
