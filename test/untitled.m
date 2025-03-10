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
plot([385, 385 + V1(2)], [667, 667 + V1(1)], 'LineWidth', 2, 'Color', 'r')
plot([385, 385 + V2(2)], [667, 667 + V2(1)], 'LineWidth', 2, 'Color', 'r')
scatter(R(2), R(1))

subplot(1, 3, 3)
imagesc2(signal2)

%%
thres = max(signal) * 0.5;
signal_filtered = signal;
signal_filtered(signal < thres) = 0;
figure
imagesc2(signal_filtered)

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
[f, xf, bw] = kde(ang, "Weight", zelux_fft(:), "Bandwidth", 1, "NumPoints", 7200);

width = 10;
peak_pos = [46.83, 134.82];
for i = 1: 2
    peak_pos(i) = findMaxPosInRange(xf, f, peak_pos(i), width);
end

%%
figure
plot(xf, f)
hold on
scatter(ang, zelux_fft(:) / sum(zelux_fft, 'all'), 2)
xline(peak_pos)

%%
k_idx = 16;

func = @(x, y) interp2(Y, X, log(zelux_fft), y, x);
k_range = linspace(0, 0.06, 500);
k_vals = [0, 0];
for i = 1: 2
    x_range = k_range * xy_size(1) * cosd(peak_pos(i)) + xy_center(1);
    y_range = k_range * xy_size(2) * sind(peak_pos(i)) + xy_center(2);
    fft_vals = func(x_range, y_range);
    plot(k_range, fft_vals)
    hold on
    k_vals(i) = findMaxPosInRange(k_range, fft_vals, 0.048, 0.001);
    xline(k_vals(i) * linspace(0, 1, k_idx + 1))
end

%%

K = [cosd(peak_pos)', sind(peak_pos)'] .* k_vals' / k_idx;
V = inv(K)';
V1 = V(1, :);
V2 = V(2, :);

%%
phase_vec = zeros(1,2);
for i = 1:2
    phase_mask = exp(-1i*2*pi*(K(i,1)*X + K(i,2)*Y));
    phase_vec(i) = angle(sum(phase_mask.*signal_filtered, 'all'));
end
R = (round([720, 540] * K(1:2,:)' + phase_vec/(2*pi)) - 1/(2*pi)*phase_vec) * V;

function xval = findMaxPosInRange(x_range, vals, center, width)
    idx_range = (x_range > center - width) & (x_range < center + width);
    box_x = x_range(idx_range);
    box_y = vals(idx_range);
    [~, new_pos] = max(box_y);
    xval = box_x(new_pos);
end
