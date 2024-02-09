%% Initialize Andor CCDs
initializeAndor()
% setCurrentAndor(19330)
setCurrentAndor(19331)

%% Acquire image from Andor
setModeFK(exposure=0.2, num_frames=2)
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