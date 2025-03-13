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
% hold on
% plot([617, 617 + 1000 * V1(2)], [901, 901 + 1000 * V1(1)], 'LineWidth', 2, 'Color', 'r')
% plot([617, 617 + 1000 * V2(2)], [901, 901 + 1000 * V2(1)], 'LineWidth', 2, 'Color', 'g')

subplot(1, 3, 3)
imagesc2(signal2)

%%
peak_ang = findFFTAngle(signal, 1, linspace(0, 180, 3600), 'ascend', true);

%%
peak_pos = findProjDensityPeak(peak_ang, signal, 1: size(signal, 1), 1: size(signal, 2), 1, 10000, true);

function [peak_pos, proj_density] = findProjDensityPeak(peak_ang, signal, x_range, y_range, bw, num_points, plot_diagnostic)
    K = [cosd(peak_ang)', sind(peak_ang)'];
    [Y, X] = meshgrid(y_range, x_range);
    Vproj = [X(:), Y(:)] * K;
    proj_density = cell(2, 2);
    peak_pos = nan(2, 2);
    for i = 1: 2
        [f, xf] = kde(Vproj(:, i), "Weight", signal(:), "Bandwidth", bw, "NumPoints", num_points);
        peak_pos(i, :) = findPeaks1D(xf, f, 2);
        proj_density{i, 1} = xf;
        proj_density{i, 2} = f;
    end
    if plot_diagnostic
        figure('Name', 'Image projection density', 'OuterPosition',[100, 100, 1600, 600])
        ax = subplot(1, 3, 1);
        imagesc2(ax, y_range, x_range, signal);
        hold(ax, "on")
        quiver(ax, (y_range(1) + y_range(end))/2, (x_range(1) + x_range(end))/2, ...
            K(1, 2), K(1, 1), 1000, 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'K1')
        quiver(ax, (y_range(1) + y_range(end))/2, (x_range(1) + x_range(end))/2, ...
            K(2, 2), K(2, 1), 1000, 'LineWidth', 2, 'Color', 'm', 'DisplayName', 'K2')
        legend(ax)
        for i = 1: 2
            subplot(1, 3, i + 1)
            plot(proj_density{i, 1}, proj_density{i, 2})
            hold on
            xline(peak_pos(i, :), '--')
            title(sprintf('V%d projection', i))
        end
    end
end


% Use kde to find two line features in FFT pattern and get normalized V
% vectors along the features as a matrix
function peak_ang = findFFTAngle(signal, bw, eval_points, peak_order, plot_diagnostic)
    signal_fft = abs(fftshift(fft2(signal)));
    xy_size = size(signal_fft);
    xy_center = floor(xy_size / 2) + 1;
    [Y, X] = meshgrid(1: xy_size(2), 1: xy_size(1));
    K = ([X(:), Y(:)] - xy_center) ./ xy_size;
    ang = atan2d(K(:, 2), K(:, 1));
    [f, xf] = kde(ang, "Weight", signal_fft(:), "Bandwidth", bw, "EvaluationPoints", eval_points);
    peak_ang = findPeaks1D(xf, f, 2);
    peak_ang = sort(peak_ang, peak_order);
    if plot_diagnostic
        figure('Name', 'FFT angular spectrum')
        plot(xf, f)
        hold on
        scatter(ang, signal_fft(:) / sum(signal_fft, 'all'), 2)
        xline(peak_ang, '--')
    end
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
