%% Some exploratory data
exposure1 = 0.1;
exposure2 = 1;

initializeCCD()
setCurrentCCD(19330)

setDataLive1("external_trigger", false, "exposure", exposure1)
image1 = acquireCCDImage();

setDataLive2("external_trigger", false, "exposure", exposure2)
image2 = acquireCCDImage();

figure
imagesc(image1)
daspect([1 1 1])

figure
imagesc(image2)
daspect([1 1 1])

%% Parameters

serial = 19330;
exposure_range = 0.01:0.01:0.1;
num_repititions = 10;
horizontal_speed_range = [0, 1, 2, 3];
vertical_speed_range = [0, 1, 2, 3, 4, 5];

%% Set up the CCD and acquire CCD image under different readout settings

initializeCCD()
setCurrentCCD(serial)

% Acquire background image

background = cell(length(horizontal_speed_range), ...
                  length(vertical_speed_range), ...
                  length(exposure_range));

for i = 1:length(horizontal_speed_range)
    horizontal_speed = horizontal_speed_range(i);

    for j = 1:length(vertical_speed_range)
        vertical_speed = vertical_speed_range(j);

        for k = 1:length(exposure_range)
            exposure = exposure_range(k);

            fprintf('Acquiring background image with exposure %f, horizontal speed %d, vertical speed %d\n', ...
                        exposure, horizontal_speed, vertical_speed)
            
            if horizontal_speed == 3
                XPixels = 100;
                YPixels = 100;
                setDataLive1(exposure=exposure, external_trigger=false, ...
                    horizontal_speed=horizontal_speed, ...
                    vertical_speed=vertical_speed, ...
                    crop=true, ...
                    crop_width=100, ...
                    crop_height=100)
            else
                XPixels = 1024;
                YPixels = 1024;
                setDataLive1(exposure=exposure, external_trigger=false, ...
                    horizontal_speed=horizontal_speed, ...
                    vertical_speed=vertical_speed)
            end

            background{i, j, k} = struct('data', zeros(XPixels, YPixels, num_repititions), ...
                'exposure', exposure, ...
                'horizontal_speed', horizontal_speed, ...
                'vertical_speed', vertical_speed);

            for p = 1:num_repititions
                fprintf('Acquiring background image %d\n', p)             
                background{i, j, k}.data(:, :, p) = acquireCCDImage();
            end

        end
    end
end

% Save background image
save('background.mat', 'background')
shutDownCCD()

%% Analyze CCD noise under different readout settings

mean_background = cell(length(horizontal_speed_range), ...
                       length(vertical_speed_range), ...
                       length(exposure_range));
std_background = cell(length(horizontal_speed_range), ...
                      length(vertical_speed_range), ...
                      length(exposure_range));

for i = 1:length(horizontal_speed_range)
    for j = 1:length(vertical_speed_range) 
        for k = 1:length(exposure_range)
            sample = background{i, j, k}.data;

            % Calculate mean and standard deviation of background image
            mean_background{i, j, k} = mean(sample, 3);
            std_background{i, j, k} = std(sample, 0, 3);
        end
    end
end

%% Some plots

a = mean_background(1, 1, :);
b = std_background(1, 1, :);

pixel_data = zeros(length(exposure_range), 1);
for k = 1:length(exposure_range)
    pixel_data(k) = mean(a{1, 1, k}, [1, 2]);
end