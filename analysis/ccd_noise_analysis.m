%% Analyze CCD noise under different readout settings

serial = 19330;
exposure_range = 0.01:0.01:0.1;
num_repititions = 10;
horizontal_speed_range = [0, 1, 2, 3];
vertical_speed_range = [0, 1, 2, 3, 4, 5];

% Set up the CCD
initializeCCD()
setCurrentCCD(serial)

% Acquire background image

background = cell(length(horizontal_speed_range), length(vertical_speed_range), length(exposure_range));

for i = 1:length(horizontal_speed_range)
    horizontal_speed = horizontal_speed_range(i);

    for j = 1:length(vertical_speed_range)
        vertical_speed = vertical_speed_range(j);

        for k = 1:length(exposure_range)
            exposure = exposure_range(k);

            fprintf('Acquiring background image with exposure %f, horizontal speed %d, vertical speed %d\n', ...
                        exposure, horizontal_speed, vertical_speed)
            
            if horizontal_speed == 3
                setDataLive1(exposure=exposure, external_trigger=false, ...
                    horizontal_speed=horizontal_speed, ...
                    vertical_speed=vertical_speed, ...
                    crop=true, ...
                    crop_width=100, ...
                    crop_height=100)
            else
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