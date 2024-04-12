%% Initialize Andor CCDs
Handle = initializeAndor();
% setCurrentAndor(19330)
setCurrentAndor(19331, Handle)
setModeFK(exposure=0.2, num_frames=8, external_trigger=false)

[ret, XPixels, YPixels] = GetDetector();
CheckWarning(ret)

%% Test fast kinetic readout
series_length = 32;
exposed_rows = 1024/series_length;
offset = 1024-1024/series_length;

[ret] = SetFastKineticsEx(exposed_rows, series_length, ...
                        0.2, 4, 1, 1, offset);
CheckWarning(ret)

%%
[ret] = FreeInternalMemory();
CheckWarning(ret)

%%
[ret] = StartAcquisition();
CheckWarning(ret)

%%
[ret, first, last] = GetNumberAvailableImages();
CheckWarning(ret)

%%
[ret, Status] = GetStatus();
CheckWarning(ret)
CheckWarning(Status)

%%
index = 2;

[ret, ImgData, ~, ~] = GetImages16(index,index,YPixels*XPixels/series_length);
CheckWarning(ret)

imageData = reshape(ImgData,YPixels,[]);

figure
imagesc(imageData)
colorbar

%%
[ret, ImgData, ~, ~] = GetImages16(first,last,YPixels*XPixels);
CheckWarning(ret)

imageData = reshape(ImgData,YPixels,[]);

figure
imagesc(imageData)
daspect([1 1 1])
colorbar

%%
[ret, ImgData] = GetAcquiredData(YPixels*XPixels);
CheckWarning(ret)

%%
image = acquireAndorImage();

figure
imagesc(image)
daspect([1 1 1])
colorbar

%% Acquire images from Andor
num_image = 0;
max_image = Inf;

fig = figure;
while num_image < max_image

    num_image = num_image + 1;
    image = acquireAndorImage(timeout=60000);
    background = acquireAndorImage();
    signal = double(image - background);

    count = mean(signal, 'all');

    figure(fig)
    subplot(1,2,1)
    imagesc(image)
    daspect([1 1 1])
    % clim([-10 50])
    colorbar
    title(sprintf('number: %d, count: %g', num_image, count))

    subplot(1,2,2)
    % imagesc(background)
    imagesc(signal(200:700, 300:800))
    daspect([1 1 1])
    clim([-10 100])
    colorbar
    
    drawnow
end

%% 
figure
plot(count_data)

%% Close Andor
closeAndor()