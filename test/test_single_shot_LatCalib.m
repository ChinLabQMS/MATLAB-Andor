%% Loading the raw dataset
clear; clc;
DataPath = 'data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat';
Data = load(DataPath, "Data").Data;
%% Preprocess the data
p = Preprocessor;
Signal = p.processData(Data);

%% Load a lattice pre-calibration
LatCalib = load('calibration/LatCalib_20241002.mat');

%% Iterate through the dataset and re-calibrate lattice vectors (and center)

CameraList = ["Andor19330", "Andor19331", "Zelux"];
LabelList = ["Image", "Image", "Lattice"];

result = struct();
for i = 1:Signal.AcquisitionConfig.NumAcquisitions
    % Iterate through all three cameras
    for j = 1: length(CameraList)
        camera = CameraList(j);
        label = LabelList(j);
        signal = Signal.(camera).(label)(:, :, i);
        [signal_box, x_range, y_range] = prepareBox(signal, LatCalib.(camera).R, 500);

        % Overlay the lattice sites on images
        %figure
        %imagesc(signal)
        %axis image
        %lat_corr = Lattice.prepareSite('hex', 'latr', 20);
        %LatCalib.(camera).plot(lat_corr)
        
        LatCalib.(camera).calibrateR(signal_box, x_range, y_range)
        % Store the updated calibration in a result variable
        result(i).(camera + "_R") = LatCalib.(camera).R;
        
        %LatCalib.(camera).plot(lat_corr)
    end
end

%%

second_image = mean(Signal.Andor19330.Image(1: 512, :, :), 3);
first_image = mean(Signal.Andor19330.Image(513: 1024, :, :), 3);

figure
imagesc(second_image)
axis image
colorbar
title("Averaged second image (FK2)")

figure
imagesc(first_image)
axis image
colorbar
title("Averaged first image(FK2)")
