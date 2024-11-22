%%
clear; clc; close all
Signal = Preprocessor().process(load("data/2024/11 November/20241113 sparse warmup/warmup_sparse.mat").Data);

%%

timestamp = Signal.Andor19330.Config.DataTimestamp - datetime([2024 11 13 13 0 0]);

x_range1 = 50:300;
y_range1 = 500:750;

x_range2 = 150:400;
y_range2 = 425:675;

figure
sample1 = Signal.Andor19330.Image(:, :, 1);
sample2 = Signal.Andor19331.Image(:, :, 1);
subplot(2, 4, 1)
imagesc2(y_range1, x_range1, sample1(x_range1, y_range1))
title(string(timestamp(1)))
subplot(2, 4, 5)
imagesc2(y_range2, x_range2, sample2(x_range2, y_range2))

sample1 = Signal.Andor19330.Image(:, :, 34);
sample2 = Signal.Andor19331.Image(:, :, 34);
subplot(2, 4, 2)
imagesc2(y_range1, x_range1, sample1(x_range1, y_range1))
title(string(timestamp(34)))
subplot(2, 4, 6)
imagesc2(y_range2, x_range2, sample2(x_range2, y_range2))

sample1 = Signal.Andor19330.Image(:, :, 67);
sample2 = Signal.Andor19331.Image(:, :, 67);
subplot(2, 4, 3)
imagesc2(y_range1, x_range1, sample1(x_range1, y_range1))
title(string(timestamp(67)))
subplot(2, 4, 7)
imagesc2(y_range2, x_range2, sample2(x_range2, y_range2))

sample1 = Signal.Andor19330.Image(:, :, 100);
sample2 = Signal.Andor19331.Image(:, :, 100);
subplot(2, 4, 4)
imagesc2(y_range1, x_range1, sample1(x_range1, y_range1))
title(string(timestamp(100)))
subplot(2, 4, 8)
imagesc2(y_range2, x_range2, sample2(x_range2, y_range2))

%%

temp = readtable("data/2024/11 November/20241119 resolution analysis/20241113_temp.csv");
figure
plot(temp.time - duration([13 0 0]), temp.temperature)
grid on
hold on
xline(duration([1 36 29]))
xline(duration([2 3 37]))
xline(duration([2 30 52]))
xline(duration([2 58 05]))
xlabel('Time')
ylabel('Temperature (F)')
