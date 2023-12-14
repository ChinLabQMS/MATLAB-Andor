%% Initialize Andor CCDs
initializeCCD()
setCurrentCCD(19330)

%% Acquire image from Andor
setDataLive1(exposure=0.01)

fig = figure;
while true
    image = acquireCCDImage();
    
    figure(fig)
    imagesc(image)
    daspect([1 1 1])
    colorbar
end

%% Close Andor
closeCCD()