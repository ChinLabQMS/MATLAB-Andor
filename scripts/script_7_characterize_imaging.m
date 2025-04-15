clear; clc; close all
p = Preprocessor();
counter = SiteCounter("Andor19331");
counter.SiteGrid.config('HexRadius', 8);

%% REP frequency scan
freqREP_range = -1.0:-0.1:-2.3;
% freqREP_val = -42.1 * freqREP_range - 315 + 251;
freqREP_val = freqREP_range;
stat = cell(1, length(freqREP_val));
for i = 1: length(freqREP_range)
    f = freqREP_range(i);
    filename = sprintf('data/2025/04 April/20250410 imaging parameter scan/Bx=-0.74_By=2.14_Bz=1.2_freqOP=-2.5_AMOP=5_freqREP=%.1f_AMREP=5.mat', f);
    Data = load(filename).Data;
    Signal = p.process(Data);
    signal = Signal.Andor19331.Image;
    stat{i} = counter.process(signal, 2);
end

err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

% figure('Position', [500, 500, 400, 200])
figure
yyaxis left
errorbar(freqREP_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('REP detuning (MHz)')
ylabel('Unpinned fraction')
yyaxis right
errorbar(freqREP_val, amp, amp_std, 's', 'CapSize', 0, 'LineWidth', 1)
ylabel('Signal level (counts)')

%% OP frequency scan
freqOP_range = [-2.0, -2.1, -2.2, -2.3, -2.4, -2.5, -2.6, ...
                -2.7, -2.8, -2.9, -3.0, -3.1, -3.2, -3.3, -3.4, -3.5];
% freqOP_val = 21.8 * freqOP_range + 64.9;
freqOP_val = freqOP_range;
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

% figure('Position', [500, 500, 400, 200])
figure
yyaxis left
errorbar(freqOP_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2)
box on
xlabel('REP detuning (MHz)')
% ylim([0, 0.5])
% xlim([-15 25])
xlabel('OP detuning (MHz)')
ylabel('Unpinned fraction')
yyaxis right
errorbar(freqOP_val, amp, amp_std, 's', 'CapSize', 0, 'LineWidth', 1)
ylabel('Signal level (counts)')

%% Bxy scan
Bx_range = [-0.09, -0.29, -0.49, -0.69, -0.79, -0.89, -1.09, -1.29, -1.49, -1.69, -1.89, -2.09];
By_range = [ 2.86,  2.64,  2.42,  2.20,  2.08,  1.97,  1.75,  1.53,  1.31,  1.08,  0.87,  0.65];
% Bxy_val = sqrt(((Bx_range - 0.01) * 75.5).^2 + ((By_range - 2.97) * 68.2).^2);
Bxy_val = Bx_range;
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

err_rate = cellfun(@(x) x.Description.MeanAll.ErrorRate, stat);
err_std = cellfun(@(x) x.Description.MeanAll.ErrorRateSTD, stat);
amp = cellfun(@(x) max(x.GMModel.mu), stat);
amp_std = cellfun(@(x) sqrt(max(x.GMModel.Sigma)), stat);

% figure('Position', [500, 500, 400, 200])
figure
e = errorbar(Bxy_val, err_rate, err_std, 'o', ...
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', [0.65 0.85 0.90],...
    'CapSize', 0, 'LineWidth', 2);
box on
xlabel('Bxy (kHz)')
ylabel('Unpinned fraction')
yyaxis right
errorbar(Bxy_val, amp, amp_std, 's', 'CapSize', 0, 'LineWidth', 1)
ylabel('Signal level (counts)')
