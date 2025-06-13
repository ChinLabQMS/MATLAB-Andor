clear; clc

data = readmatrix('data/2025/05 May/20250530/refresh_rate_cleaned.csv');
x = data(:, 1);
y = data(:, 2);
z = movmean(y, 10);

%%
z = (z - min(z)) / (max(z) - min(z));

% idx = (x > 0.0002) & (x < 0.0003);
idx = (x > 0) & (x < 0.004);
plot(x(idx) * 1e3, z(idx))
xlabel('Time (ms)')
ylabel('DMD signal (arb.)')
