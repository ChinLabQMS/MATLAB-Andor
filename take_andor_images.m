%% Initialize Andor CCDs
initializeCCD()
setCurrentCCD(19330)

%% Acquire image from Andor
setDataLive1(exposure=0.01)
num_image = 0;

fig = figure;
while true
    image = acquireCCDImage();
    
    num_image = num_image + 1;
    figure(fig)
    imagesc(image)
    daspect([1 1 1])
    colorbar
    title(sprintf('number: %d', num_image))
end

%% Close Andor
closeCCD()