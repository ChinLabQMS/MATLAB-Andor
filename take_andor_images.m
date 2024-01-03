%% Initialize Andor CCDs
initializeAndor()
setCurrentAndor(19330)

%% Acquire image from Andor
setModeLive1(exposure=0.01)
num_image = 0;

fig = figure;
while true
    image = acquireAndorImage();
    
    num_image = num_image + 1;
    figure(fig)
    imagesc(image)
    daspect([1 1 1])
    colorbar
    title(sprintf('number: %d', num_image))
end

%% Close Andor
closeAndor()