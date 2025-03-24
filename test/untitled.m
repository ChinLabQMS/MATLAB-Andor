clear; clc; close all

Data = load("data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat").Data;
% Data = load("data/2025/03 March/20250319/dense_calibration.mat").Data;
load("calibration/LatCalib.mat")

p = Preprocessor();
Signal = p.process(Data);

%%
signal = Signal.Zelux.Pattern_532(:, :, 1);
x_range = 1: size(signal, 1);
y_range = 1: size(signal, 2);

signal2 = mean(Signal.Andor19330.Image, 3);
[signal2, x_range2, y_range2] = prepareBox(signal2, Andor19330.R, 200);

Andor19330.calibrateR(signal2, x_range2, y_range2)

%%
figure
imagesc2(y_range2, x_range2, signal2)
Andor19330.plot()

%%
Zelux.calibrateProjectorVRHash(signal)
ZeluxInit = Zelux.copy();

%%
Zelux.calibrateO(Andor19330, signal, signal2, x_range, y_range, x_range2, y_range2, ...
    "inverse_match", true, "covert_to_signal", false, "calib_R", false, "sites", SiteGrid.prepareSite("Hex", "latr", 20), ...
    "plot_diagnosticO", true, "verbose", true, "debug", true)

%%
transformed2 = Zelux.transformSignal(Andor19330, x_range2, y_range2, signal);

figure
subplot(1, 2, 1)
imagesc2(y_range2, x_range2, transformed2)
subplot(1, 2, 2)
imagesc2(y_range2, x_range2, signal2)

%%
sites = SiteGrid.prepareSite('Hex', 'latr', 20);
num_sites = size(sites, 1);
score.Site = sites;
score.Center = ZeluxInit.convert2Real(sites, "filter", false);
score.SignalDist = nan(num_sites, 1);

for i = 1: size(sites, 1)
    Zelux.init(score.Center(i, :), 'format', "R")
    transformed2 = Zelux.transformSignal(Andor19330, x_range2, y_range2, signal);
    score.SignalDist(i) = pdist2(transformed2(:)', signal2(:)', "cosine");
end
score = struct2table(score);

%%
plotSimilarityMap(x_range, y_range, score)

function plotSimilarityMap(x_range, y_range, score)
    empty_image = zeros(length(x_range), length(y_range));
    score.Similarity = max(score.SignalDist) - score.SignalDist;
    figure('Name', 'Cross-calibration: Similarity map with scanning lattice origin')
    imagesc2(y_range, x_range, empty_image, "title", 'Similarity between images from different cameras')
    hold on
    % scatter(best.Center(2), best.Center(1), 100, "red")
    scatter(score.Center(:, 2), score.Center(:, 1), 50, score.Similarity, 'filled')
end

%%
DMD.calibrateProjector2Camera(Zelux)
