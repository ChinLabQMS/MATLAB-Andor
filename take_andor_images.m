%% Initialize Andor CCDs
initializeAndor()
setCurrentAndor(19330)

%% Acquire image from Andor
setModeFull(exposure=0.01)
num_image = 0;
max_image = 100;

fig = figure;
while num_image < max_image

    num_image = num_image + 1;
    image = acquireAndorImage();
    background = acquireAndorImage();
    signal = double(image - background);
    
    figure(fig)
    imagesc(signal)
    daspect([1 1 1])
    clim([0 10])
    colorbar
    title(sprintf('number: %d, count: %d', num_image, sum(signal, 'all')))
    drawnow
end

%% Close Andor
closeAndor()