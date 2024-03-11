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
                       'Zelux', struct());
RawBackground.Config = struct('HSSpeed',2,'VSSpeed',1, ...
    'ExpsoureUnit','ms','ExposureFormat','Exposure_%d');

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