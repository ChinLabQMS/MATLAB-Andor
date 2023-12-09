%% Analyze CCD noise under different readout settings

serial = 19330;
exposure_range = 0.01:0.01:0.2;
num_repititions = 20;
horizontal_speed_range = [0, 1, 2, 3];
vertical_speed_range = [0, 1, 2, 3, 4, 5];

XPixels = 1024;
YPixels = 1024;

%% Set up the CCD
initializeCCD()
SetCurrentCCD(serial)

%% Acquire background image

background = cell(length(horizontal_speed_range), length(vertical_speed_range), length(exposure_range));

for i = 1:length(horizontal_speed_range)
    horizontal_speed = horizontal_speed_range(i);

    for j = 1:length(vertical_speed_range)
        vertical_speed = vertical_speed_range(j);

        for k = 1:length(exposure_range)
            exposure = exposure_range(k);

            fprintf('Acquiring background image with exposure %f, horizontal speed %d, vertical speed %d\n', ...
                        exposure, horizontal_speed, vertical_speed)
            setDataLive1(exposure=exposure, external_trigger=false, ...
                horizontal_speed=horizontal_speed, ...
                vertical_speed=vertical_speed)

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
shutdownCCD()

%% Save background image
