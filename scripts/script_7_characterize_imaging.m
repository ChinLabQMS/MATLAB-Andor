clear; clc; close all
p = Preprocessor();
counter = SiteCounter("Andor19331");
counter.configGrid('HexRadius', 8);

%% REP frequency scan
freqREP_range = -1.0:-0.1:-2.3;
freqREP_val = -42.1 * freqREP_range - 315 + 251;
% freqREP_val = freqREP_range;
stat = cell(1, length(freqREP_val));
for i = 1: length(freqREP_range)
    f = freqREP_range(i);
    filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=-0.74_By=2.14_Bz=1.2_freqOP=-2.5_AMOP=5_freqREP=%.1f_AMREP=5.mat', f);
    Data = load(filename).Data;
    Signal = p.process(Data);
    signal = Signal.Andor19331.Image;
    stat{i} = counter.process(signal, 2);
end
%%
err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

figure('Position', [500, 500, 400, 200])
yyaxis left
errorbar(freqREP_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Repumping detuning (MHz)')
ylabel('Error fraction')
yyaxis right
fill([freqREP_val, fliplr(freqREP_val)], [amp + amp_std, fliplr(amp - amp_std)], [1, 0, 0], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.1)
ylabel('Counts per site')
ylim([0, inf])
xlim([-25, 35])

%% OP frequency scan
freqOP_range = [-2.0, -2.1, -2.2, -2.3, -2.4, -2.5, -2.6, ...
                -2.7, -2.8, -2.9, -3.0, -3.1, -3.2, -3.3, -3.4, -3.5];
freqOP_val = 21.8 * freqOP_range + 64.9;
% freqOP_val = freqOP_range;
stat = cell(1, length(freqOP_val));
for i = 1: length(freqOP_range)
    f = freqOP_range(i);
    filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=-0.74_By=2.14_Bz=1.2_freqOP=%.1f_AMOP=5_freqREP=-1.4_AMREP=5.mat', f);
    Data = load(filename).Data;
    Signal = p.process(Data);
    signal = Signal.Andor19331.Image;
    stat{i} = counter.process(signal, 2);
end
%%
err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

figure('Position', [500, 500, 400, 200])
yyaxis left
errorbar(freqOP_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
ylim([0, 0.5])
xlabel('Optical pumping detuning (MHz)')
ylabel('Error fraction')
yyaxis right
fill([freqOP_val, fliplr(freqOP_val)], [amp + amp_std, fliplr(amp - amp_std)], [1, 0, 0], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.1)
ylabel('Counts per site')

%% Bxy scan
Bx_range = [-0.09, -0.29, -0.49, -0.69, -0.79, -0.89, -1.09, -1.29, -1.49, -1.69, -1.89, -2.09];
By_range = [ 2.86,  2.64,  2.42,  2.20,  2.08,  1.97,  1.75,  1.53,  1.31,  1.08,  0.87,  0.65];
Bxy_val = sqrt(((Bx_range - 0.01) * 75.5).^2 + ((By_range - 2.97) * 68.2).^2);
% Bxy_val = Bx_range;
stat = cell(1, length(Bxy_val));
for i = 1: length(Bxy_val)
    Bx = Bx_range(i);
    By = By_range(i);
    filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=%.2f_By=%.2f_Bz=1.2_freqOP=-2.55_AMOP=5_freqREP=-1.4_AMREP=5.mat', Bx, By);
    Data = load(filename).Data;
    Signal = p.process(Data);
    signal = Signal.Andor19331.Image;
    stat{i} = counter.process(signal, 2);
end
%%
err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

figure('Position', [500, 500, 400, 200])
yyaxis left
errorbar(Bxy_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Bxy (kHz)')
ylabel('Error fraction')
yyaxis right
fill([Bxy_val, fliplr(Bxy_val)], [amp + amp_std, fliplr(amp - amp_std)], [1, 0, 0], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.1)
ylabel('Counts per site')
ylim([0, inf])

%% Bz scan
Bz_range = [0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.5, 3.0, 4.0];
Bz_val = (Bz_range - 4.73) * 74.6 / 350;
% Bz_val = Bx_range;
stat = cell(1, length(Bz_val));

for i = 1: length(Bz_val)
    Bz = Bz_range(i);
    filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=-0.79_By=2.08_Bz=%.1f_freqOP=-2.55_AMOP=5_freqREP=-1.4_AMREP=5.mat', Bz);
    Data = load(filename).Data;
    Signal = p.process(Data);
    signal = Signal.Andor19331.Image;
    stat{i} = counter.process(signal, 2);

end
%%
err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

figure('Position', [500, 500, 400, 200])
yyaxis left
errorbar(Bz_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('Bz (G)')
ylabel('Error fraction')
yyaxis right
fill([Bz_val, fliplr(Bz_val)], [amp + amp_std, fliplr(amp - amp_std)], [1, 0, 0], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.1)
ylabel('Counts per site')
ylim([0, inf])
xlim([-1.05, -0.1])

%% Bz pictures
Bz = 1.2;
Bz_val = (Bz - 4.73) * 74.6 / 350;
filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=-0.79_By=2.08_Bz=%.1f_freqOP=-2.55_AMOP=5_freqREP=-1.4_AMREP=5.mat', Bz);
Data = load(filename).Data;
Signal = p.process(Data);
signal = Signal.Andor19331.Image;
stat0 = counter.process(signal, 2);

% x_range = 1:512;
% y_range = 1:1024;
x_range = 1:451;
y_range = 440:890;

figure
imagesc(signal(x_range, y_range, 1))
daspect([1 1 1])
clim([-10, inf])
xticks([])
yticks([])
cb = colorbar();
cb.Ticks = [10, cb.Ticks(end)];
cb.FontSize = 16;
title(sprintf('Bz = %.2f G', Bz_val), 'FontSize', 16)
