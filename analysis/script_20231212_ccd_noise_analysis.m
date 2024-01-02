%% Parameters

num_repititions = 20;
horizontal_speed_range = [0,1,2,3];
vertical_speed_range = [0,1,2,3,4,5];

%% Set up the CCD and acquire CCD image under different readout settings
% Cap the CCD for the background measurements

initializeCCD()
for serial_number = [19330,19331]
    setCurrentCCD(serial_number)
    
    % Acquire background image
    background = cell(length(horizontal_speed_range), ...
                      length(vertical_speed_range));
    
    for i = 1:length(horizontal_speed_range)
        horizontal_speed = horizontal_speed_range(i);
    
        for j = 1:length(vertical_speed_range)
            vertical_speed = vertical_speed_range(j);
    
            fprintf('Acquiring background image with horizontal speed %d, vertical speed %d\n', ...
                        horizontal_speed, vertical_speed)
            
            if horizontal_speed == 3
                XPixels = 100;
                YPixels = 100;
                setDataLive1( ...
                    'exposure',0.01, ...
                    'external_trigger',false, ...
                    'horizontal_speed',horizontal_speed, ...
                    'vertical_speed',vertical_speed, ...
                    'crop',true, ...
                    'crop_width',100, ...
                    'crop_height',100)
            else
                XPixels = 1024;
                YPixels = 1024;
                setDataLive1( ...
                    'exposure',0.01, ...
                    'external_trigger',false, ...
                    'horizontal_speed',horizontal_speed, ...
                    'vertical_speed',vertical_speed)
            end
    
            background{i,j} = struct( ...
                'data',zeros(XPixels,YPixels,num_repititions,'uint16'), ...
                'horizontal_speed',horizontal_speed, ...
                'vertical_speed',vertical_speed);
    
            for p = 1:num_repititions
                fprintf('Acquiring background image %d\n', p)             
                background{i,j}.data(:,:,p) = acquireCCDImage();
            end
    
        end
    end

    % Save background image
    save(sprintf('background_%d.mat',serial_number),'background')
end
closeCCD()

%% CCD photon to count gain calibration
% Expose the CCD to some ambient light for this measurement

exposure_range = 0.2:0.2:4;

initializeCCD()
for serial_number = [19330, 19331]
    setCurrentCCD(serial_number)
    
    signal = cell(length(exposure_range), 1);

    % Acquire background images
    for i = 1:length(exposure_range)
        exposure = exposure_range(i);
        fprintf('Acquiring background image with exposure time %.1fs\n', ...
            exposure)

        setDataLive1( ...
            "exposure",exposure, ...
            "external_trigger",false)
        
        signal{i} = struct( ...
            'data',zeros(1024,1024,num_repititions,'uint16'), ...
            'exposure',exposure);

        for j = 1:num_repititions
            fprintf('Acquiring background image %d\n', j)
            signal{i}.data(:,:,j) = acquireCCDImage();
        end
    end

    % Save signal data
    save(sprintf('signal_%d.mat',serial_number),'signal')
end
closeCCD()

%% Analyze CCD noise under different readout settings

mean_background = cell(length(horizontal_speed_range), ...
                       length(vertical_speed_range));
std_background = cell(length(horizontal_speed_range), ...
                      length(vertical_speed_range));

for i = 1:length(horizontal_speed_range)
    for j = 1:length(vertical_speed_range)
        sample = double(background{i,j}.data);
    
        % Calculate mean and standard deviation of background image
        mean_background{i,j} = mean(sample,3);
        std_background{i,j} = std(sample,0,3);
    end
end

%%
horizontal = [5,3,1,0.05];
vertical = [2.25,4.25,8.25,16.25,32.25,64.25];

figure
for i = 1:length(horizontal_speed_range)
    for j = 1:length(vertical_speed_range)
        subplot(length(horizontal_speed_range), ...
            length(vertical_speed_range), ...
            (i - 1)*length(vertical_speed_range) + j)
        imagesc(mean_background{i,j})
        daspect([1 1 1])
        xticks([])
        yticks([])
        colorbar
        title(sprintf('Horizontal speed %g MHz\nvertical speed %g us', ...
            horizontal(i), vertical(j)))
    end
end

figure
for i = 1:length(horizontal_speed_range)
    for j = 1:length(vertical_speed_range)
        subplot(length(horizontal_speed_range), ...
            length(vertical_speed_range), ...
            (i - 1)*length(vertical_speed_range) + j)
        imagesc(std_background{i,j})
        daspect([1 1 1])
        xticks([])
        yticks([])
        colorbar
        title(sprintf('Horizontal speed %g MHz\nvertical speed %g us', ...
            horizontal(i), vertical(j)))
    end
end

%% Some plots

x = 500;
y = 500;
pixel_mean = zeros(length(exposure_range),1);
pixel_var = zeros(length(exposure_range),1);
for k = 1:length(exposure_range)
    pixel_mean(k) = mean_background{1,1,k}(x,y);
    pixel_var(k) = std_background{1,1,k}(x,y) ^ 2;
end

figure
subplot(2,1,1)
plot(exposure_range,pixel_mean)

subplot(2,1,2)
plot(exposure_range,pixel_var)