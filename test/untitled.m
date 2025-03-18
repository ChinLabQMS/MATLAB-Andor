clear; clc; close all

% Data = load("data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat").Data;
Data = load("data/2025/03 March/20250317/dense_calibration.mat").Data;
load("calibration/LatCalib.mat")

p = Preprocessor();
Signal = p.process(Data);

%%
% template = imread("resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp");
signal = Signal.Zelux.Pattern_532(:, :, 1);
signal2 = mean(Signal.Andor19330.Image, 3);

%%
DMD.calibrateProjectorPattern(signal, Zelux)

%%
figure
imagesc2(signal2)



function [proj_density, K] = getProjectionDensity(proj_ang, signal, x_range, y_range, bw, num_points)
    num_ang = length(proj_ang);
    K = [cosd(proj_ang)', sind(proj_ang)'];
    [Y, X] = meshgrid(y_range, x_range);
    Kproj = [X(:), Y(:)] * K';
    proj_density = cell(num_ang, 2);
    for i = 1: num_ang
        [f, xf] = kde(Kproj(:, i), "Weight", signal(:), "Bandwidth", bw, "NumPoints", num_points);
        proj_density{i, 1} = xf;
        proj_density{i, 2} = f;
    end
end

