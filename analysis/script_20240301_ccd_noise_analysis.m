% path = 'C:\Users\qmspc\Desktop\NewLabData\2024\03 March\2024-03-01 Camera acquisition test';
path = 'D:\QMS-DATA\2024\03 March\2024-03-01 Camera acquisition test';

Background = struct();
for exposure = [0, 200, 400, 600, 800, 1000]
    filename = sprintf('Data_exposure=%dms.mat', exposure);
    Background.(sprintf('Exposure_%d', exposure)) = load(fullfile(path, filename), 'Data').Data;
end

%%
sample = Background.Exposure_0{1}.Image;

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
RawBackground.Config = struct('Readout', []);
cameras = fieldnames(RawBackground);
for i = 1:length(cameras)
    camera = cameras{i};
    for exposure = 0:200:1000
        RawBackground.(camera).(sprintf(''))
    end
end