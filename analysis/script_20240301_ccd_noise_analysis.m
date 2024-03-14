path = 'C:\Users\qmspc\Desktop\NewLabData\2024\03 March\2024-03-01 Camera acquisition test';
% path = 'D:\QMS-DATA\2024\03 March\2024-03-01 Camera acquisition test';

Background = struct();
% exposure_range = 0:200:1000;
for exposure = 0:200:1000
% for i = 1:length(exposure)
    % exposure = exposure_range(i);
    filename = sprintf('Data_exposure=%dms.mat', exposure);
    Background.(sprintf('Exposure_%d', exposure)) = load(fullfile(path, filename), 'Data').Data;
    disp(filename)
end

%%
sample = Background.Exposure_200{1}.Image;

mean_image = mean(double(sample), 3);
figure
imagesc(mean_image)
daspect([1 1 1])
colorbar

std_image = std(double(sample), 0, 3);
figure
imagesc(std_image)
daspect([1 1 1])
colorbar

%% Re-sturcture the raw background data
RawBackground = struct('Andor19330', struct(), ...
                       'Andor19331', struct(), ...
                       'Zelux', struct(), ...
                       'Config', struct('HSSpeed',2,'VSSpeed',1, ...
                                        'ExpsoureUnit','ms','ExposureFormat','Exposure_%d'));

for exposure = [0, 200, 400, 600, 800, 1000]
    name = sprintf('Exposure_%d', exposure);
    disp(name)
    for i = 1:length(Background.(name))
        camera = Background.(name){i}.Config.Serial;
        label = Background.(name){i}.Config.Acquisition{1};
        % disp(camera)
        % disp(label)
        RawBackground.(camera).(name) = Background.(name){i}.(label);
    end
end
RawBackground = rmfield(RawBackground, 'Zelux');

%%
save("calibration\RawBackground_20240301_HSSpeed=2_VSSpeed=1", "-struct", "RawBackground")

%% 
RawBackground = load('calibration\RawBackground_20240301_HSSpeed=2_VSSpeed=1.mat');

%%
images = RawBackground.Andor19330.Exposure_0;
new_images = removeOutliers(images);

subplot(1,2,1)
imagesc(mean(images,3))
daspect([1 1 1])
colorbar

subplot(1,2,2)
imagesc(mean(new_images,3,'omitmissing'))
daspect([1 1 1])
colorbar

%%
StatBackground = struct();

cameras = {'Andor19330','Andor19331'};
for i = 1:length(cameras)
    camera = cameras{i};
    labels = fieldnames(RawBackground.(camera));
    StatBackground.(camera) = struct();

    for j = 1:length(labels)
        label = labels{j};
        disp(camera)
        disp(label)
        images = removeOutliers(RawBackground.(camera).(label));
        StatBackground.(camera).(label) = struct( ...
            'Mean', mean(images, 3, 'omitmissing'), ...
            'STD', std(images, 0, 3, 'omitmissing'));
    end
end

save('calibration\StatBackground_20240301_HSSpeed=2_VSSpeed=1.mat', '-struct', 'StatBackground')

%%
StatBackground = load("calibration\StatBackground_20240301_HSSpeed=2_VSSpeed=1.mat");

%%
subplot(1,2,1)
imagesc(StatBackground.Andor19330.Exposure_0.Mean)
daspect([1 1 1])
colorbar

subplot(1,2,2)
imagesc(StatBackground.Andor19330.Exposure_0.STD)
daspect([1 1 1])
colorbar

%% Look at caoped "clean" background
CleanBackground = struct('Andor19330', struct(), ...
                         'Andor19331', struct(), ...
                         'Config', struct('HSSpeed',2,'VSSpeed',1, ...
                                          'XPixels',1024,'YPixels',1024, ...
                                          'MaxImage',100, ...
                                          'Exposure', 1e-5));
CleanBackground.Andor19330 = Data.Andor19330.Image;
CleanBackground.Andor19331 = Data.Andor19331.Image;

save('calibration\CleanBackground_20240311_HSSpeed=2_VSSpeed=1.mat', '-struct', 'CleanBackground')

%%
CleanBackground = load('calibration\CleanBackground_20240311_HSSpeed=2_VSSpeed=1.mat');

%% Get the statistics of the clean background
StatBackground = struct();
StatBackground.Config = CleanBackground.Config;

cameras = {'Andor19330','Andor19331'};
for i = 1:length(cameras)
    camera = cameras{i};
    StatBackground.(camera) = struct();
    images = removeOutliers(CleanBackground.(camera));
    StatBackground.(camera) = struct( ...
        'Mean', mean(images, 3, 'omitmissing'), ...
        'Var', var(images, 0, 3, 'omitmissing'));
end

%%
camera = 'Andor19331';
mean_image = StatBackground.(camera).Mean;
var_image = StatBackground.(camera).Var;

%%
figure
subplot(1,3,1)
imagesc(StatBackground.(camera).Mean)
daspect([1 1 1])
colorbar

subplot(1,3,2)
imagesc(StatBackground.(camera).Var)
daspect([1 1 1])
colorbar

subplot(1,3,3)
surf(StatBackground.(camera).Mean, 'EdgeColor','none')

%% Distribution of the variance, and test the variance of the variance distribution
v = var(StatBackground.Andor19330.Var, 0, 'all');
v_predicted = 2*mean(StatBackground.Andor19330.Var, 'all')^2/(StatBackground.Config.MaxImage-1);

figure
histogram(StatBackground.(camera).Var(:), 100)
title(sprintf('v = %.3f, v_{pred} = %.3f', v, v_predicted))

%% Test some smoothing algorithm
mean_fft = abs(fftshift(fft2(mean_image)));

figure
histogram(log(mean_fft),'EdgeColor','none')

%%
mask = log(mean_fft) > 7.7;
mean_new = abs(ifft2(ifftshift(fftshift(fft2(mean_image)) .* mask)));

figure
subplot(1,3,1)
imagesc(mean_image)
daspect([1 1 1])
colorbar

subplot(1,3,2)
imagesc(mean_new)
daspect([1 1 1])
colorbar

subplot(1,3,3)
imagesc(mean_new - mean_image)
daspect([1 1 1])
colorbar

%%
figure
subplot(1,2,1)
histogram(mean_new - mean_image,'EdgeColor','none')
legend('diff')
title(sprintf('Mean: %g', mean(mean_new - mean_image,'all')))

subplot(1,2,2)
histogram(mean_image,'EdgeColor','none')
hold on
histogram(mean_new,'EdgeColor','none')
legend({'mean','new'})

%%
figure
subplot(1,2,1)
surf(mean_new - mean_image,'EdgeColor','none')

subplot(1,2,2)
surf(mean_new,'EdgeColor','none')

%%
diff_fft = abs(fftshift(fft(mean_new - mean_image)));

figure
imagesc(log(diff_fft))
colorbar

%%
StatBackground.(camera).SmoothMean = mean_new;
StatBackground.(camera).NoiseVar = mean(var_image,'all');

%%
save('calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat', '-struct', 'StatBackground')

%%
StatBackground = load('calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat');