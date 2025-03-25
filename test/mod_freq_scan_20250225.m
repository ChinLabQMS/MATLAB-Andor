freq = [1, 2, 5, 10, 20, 50, 100];
x_range = 50:400;
y_range = 250:650;

p = Preprocessor();
count1 = zeros(1, length(freq));
count2 = zeros(1, length(freq));
for i = 1: length(freq)
    filename = fullfile('data/2025/02 February/20250228/', sprintf('halfplane_mod=%dkHz.mat', freq(i)));
    Data = load(filename).Data;

    Signal = p.process(Data);

    count1(i) = sum(Signal.Andor19330.Image(x_range, y_range, :), 'all');
    count2(i) = sum(Signal.Andor19330.Image(x_range + 512, y_range, :), 'all');
end

%%
Data = load("data/2025/02 February/20250225/solid_gray.mat").Data;
Signal = p.process(Data);
gray1 = sum(Signal.Andor19330.Image(x_range, y_range, :), 'all');
gray2 = sum(Signal.Andor19330.Image(x_range + 512, y_range, :), 'all');

%%
Data = load("data/2025/02 February/20250225/no_532.mat").Data;
Signal = p.process(Data);
bg1 = sum(Signal.Andor19330.Image(x_range, y_range, :), 'all');
bg2 = sum(Signal.Andor19330.Image(x_range + 512, y_range, :), 'all');

%%
figure
plot(freq, count1, 'o-', freq, count2, 'o-', 'LineWidth', 2)
% hold on
% yline(gray1, '--', 'LineWidth', 2)
% yline(gray2, '--', 'LineWidth', 2)
% plot(1.44, gray1, 'o', 1.44, gray2, 'o')
legend('counts in second image', 'counts in first image')
xlabel('modulation frequency (kHz)')

%%
figure
plot(freq, count1./count2, 'o-', 'LineWidth', 2)
% hold on
% yline(gray1/gray2, '--', 'LineWidth', 2)
legend('counts ratio', 'modulation with gray pattern (1.44kHz)')
xlabel('modulation frequency (kHz)')

%%
x_range = 200:260;
y_range = 400:550;

figure
for i = 1: length(freq)
    filename = fullfile('data/2025/02 February/20250228/', sprintf('halfplane_mod=%dkHz.mat', freq(i)));
    Data = load(filename).Data;

    Signal = p.process(Data);
    
    subplot(length(freq), 1, i)
    mean_image = mean(Signal.Andor19330.Image, 3);
    imagesc2(y_range, x_range, mean_image(x_range, y_range))
    Andor19330.plot('filter', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])
end

%%
Signal = p.process(Data);
x_range = 200: 400;
y_range = 500:800;
mean_image = mean(Signal.Andor19331.Image, 3);
figure
subplot(2, 1, 1)
imagesc2(y_range, x_range, mean_image(x_range + 512, y_range))
Andor19331.plot()
ylim([x_range(1), x_range(end)])
xlim([y_range(1), y_range(end)])
title('Start')

subplot(2, 1, 2)
imagesc2(y_range, x_range, mean_image(x_range, y_range))
Andor19331.plot()
ylim([x_range(1), x_range(end)])
xlim([y_range(1), y_range(end)])
title('End')

%%
sz = [2, 5, 10, 20, 50, 100, 200];
x_range = 50:400;
y_range = 250:650;

p = Preprocessor();
count1 = zeros(1, length(sz));
count2 = zeros(1, length(sz));
for i = 1: length(sz)
    filename = fullfile('data/2025/02 February/20250227/', sprintf('checkerboard_size=%d_with_mod.mat', sz(i)));
    Data = load(filename).Data;

    Signal = p.process(Data);

    count1(i) = sum(Signal.Andor19330.Image(x_range, y_range, :), 'all');
    count2(i) = sum(Signal.Andor19330.Image(x_range + 512, y_range, :), 'all');
end

%%
Data = load("data/2025/02 February/20250227/solid_white_with_mod.mat").Data;
Signal = p.process(Data);
white1 = sum(Signal.Andor19330.Image(x_range, y_range, :), 'all');
white2 = sum(Signal.Andor19330.Image(x_range + 512, y_range, :), 'all');

%%
figure
plot(sz, count1, 'o-', sz, count2, 'o-', 'LineWidth', 2)
hold on
yline(white1, '--', 'LineWidth', 2)
yline(white2, '--', 'LineWidth', 2)
legend('counts in second image', 'counts in first image')
xlabel('checkerboard size')

figure
plot(sz, count1./count2, 'o-', 'LineWidth', 2)
hold on
yline(white1/white2, '--', 'LineWidth', 2)
legend('counts ratio', 'counts ratio with solid white pattern')
xlabel('checkerboard size')

%%
Signal = p.process(Data);

%%
figure
imagesc2(mean(Signal.Andor19331.Image, 3))
Andor19331.plot()
