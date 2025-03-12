clear; clc; close all

Data = load("data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat").Data;
p = Preprocessor();
Signal = p.process(Data);

%%
template = imread("resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp");
signal = Signal.Zelux.Pattern_532(:, :, 1);
signal2 = mean(Signal.Andor19330.Image, 3);

figure
subplot(1, 3, 1)
imagesc2(template)
subplot(1, 3, 2)
imagesc2(signal)
hold on
plot([617, 617 + 1000 * V1(2)], [901, 901 + 1000 * V1(1)], 'LineWidth', 2, 'Color', 'r')
plot([617, 617 + 1000 * V2(2)], [901, 901 + 1000 * V2(1)], 'LineWidth', 2, 'Color', 'g')

subplot(1, 3, 3)
imagesc2(signal2)

%%
zelux_fft = abs(fftshift(fft2(signal)));
xy_size = size(zelux_fft);
[Y, X] = meshgrid(1: xy_size(2), 1: xy_size(1));
xy_center = floor(xy_size / 2) + 1;
K = ([X(:), Y(:)] - xy_center) ./ xy_size;
ang = atan2d(K(:, 2), K(:, 1));

%%
figure
subplot(1, 2, 1)
imagesc2(log(zelux_fft))

subplot(1, 2, 2)
imagesc2(reshape(ang, xy_size))
colorbar

%%
[f, xf] = kde(ang, "Weight", zelux_fft(:), "Bandwidth", 1, "EvaluationPoints", linspace(0, 180, 3600));

peak_ang = findPeaks1D(xf, f, 2);
peak_ang = sort(peak_ang, 'descend');

%%
figure
plot(xf, f)
hold on
scatter(ang, zelux_fft(:) / sum(zelux_fft, 'all'), 2)
xline(peak_ang)

%%
V = [-sind(peak_ang)', cosd(peak_ang)'];
V1 = V(1, :);
V2 = V(2, :);

Vproj = [X(:), Y(:)] * V';

figure
subplot(1, 2, 1)
% imagesc2(reshape(V1proj, xy_size))
scatter(Vproj(:, 1), signal(:), 2)
subplot(1, 2, 2)
% imagesc2(reshape(V2proj, xy_size))
scatter(Vproj(:, 2), signal(:), 2)

%%
[f, xf] = kde(Vproj(:, 2), "Weight", signal(:), "Bandwidth", 1, "NumPoints", 10000);

%%
peak_pos = findPeaks1D(xf, f, 2);

figure
plot(xf, f)
hold on
xline(peak_pos)

function xval = findMaxPosInRange(x_range, vals, center, width)
    idx_range = (x_range > center - width) & (x_range < center + width);
    box_x = x_range(idx_range);
    box_y = vals(idx_range);
    [~, new_pos] = max(box_y);
    xval = box_x(new_pos);
end

function [peak_x, peak_y, peak_idx] = findPeaks1D(x, y, num_peaks)
    peak_x = [];
    peak_y = [];
    peak_idx = [];
    for i = 2: length(x) - 1
        if y(i) > y(i - 1) && y(i) > y(i + 1)
            peak_x(end + 1) = x(i); %#ok<AGROW>
            peak_y(end + 1) = y(i); %#ok<AGROW>
            peak_idx(end + 1) = i; %#ok<AGROW>
        end
    end
    [~, sort_idx] = sort(peak_y, 'descend');
    sort_idx = sort_idx(1: num_peaks);
    peak_x = peak_x(sort_idx);
    peak_y = peak_y(sort_idx);
    peak_idx = peak_idx(sort_idx);
end
