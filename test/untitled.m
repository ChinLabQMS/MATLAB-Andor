clear; clc; close all

% Data = load("data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat").Data;
Data = load("data/2025/03 March/20250319/dense_calibration.mat").Data;
load("calibration/LatCalib.mat")

p = Preprocessor();
Signal = p.process(Data);

% template = imread("resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp");
signal = Signal.Zelux.Pattern_532(:, :, 1);
signal2 = mean(Signal.Andor19330.Image, 3);

%%
figure
imagesc2(signal2)
% Andor19330.plot()

%%
DMD.calibrateProjectorPattern(signal, Zelux)

V = [1, 0; 0, 1] / DMD.V * Andor19330.V;

%%
figure
imagesc2(signal2)
Andor19330.plot()
Andor19330.plotV('vector', V, 'scale', 150)

%%
[signal_box, x_range, y_range] = prepareBox(signal2, Andor19330.R, 200);

figure
imagesc2(y_range, x_range, signal_box)
Andor19330.plotV('vector', V, 'scale', 100)

%%
proj_ang = acotd(V(:, 2) ./ V(:, 1))';

proj_density = getProjectionDensity(proj_ang, abs(signal_box), x_range, y_range, 1, 10000, Andor19330);


function [proj_density, K] = getProjectionDensity(proj_ang, signal, x_range, y_range, bw, num_points, Lat)
    num_ang = length(proj_ang);
    K = [cosd(proj_ang)', sind(proj_ang)'];
    [Y, X] = meshgrid(y_range, x_range);
    Kproj = [X(:), Y(:)] * K';
    proj_density = cell(num_ang, 2);
    figure
    for i = 1: num_ang
        [f, xf] = kde(Kproj(:, i), "Weight", signal(:), "Bandwidth", bw, "NumPoints", num_points);
        proj_density{i, 1} = xf;
        proj_density{i, 2} = f;
        subplot(1, num_ang, i)
        scatter(Kproj(:, i), signal(:) / sum(signal(:)))
        hold on
        plot(xf, f)
    end
end

