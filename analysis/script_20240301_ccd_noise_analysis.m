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
save("RawBackground_20240301_HSSpeed=2_VSSpeed=1", "-struct", "RawBackground")

%% 
RawBackground = load('calibration\RawBackground_20240301_HSSpeed=2_VSSpeed=1.mat');

%% Get the mean and variance of the data with 2 max filtered
StatBackground = struct();
cameras = fieldnames(RawBackground);
for i = 1:length(cameras)
    camera = cameras{i};
    names = fieldnames(RawBackground);
    for j = 1:length(names)
        StatBackground.(camera).(names{j}) = struct( ...
            'Mean', trimmean(RawBackground.(camera).(name{j}), 5, 3), ...
            'STD', trimstd())
    end
end