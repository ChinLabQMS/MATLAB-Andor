%% Initialize Zelux camera
[tlCameraSDK, tlCamera] = initializeZelux();

%% Acquire images from Zelux
num_image = 0;
max_image = Inf;

fig = figure;
while num_image < max_image

    image_lattice = acquireZeluxImage(tlCamera);
    image_dmd = acquireZeluxImage(tlCamera);
    
    figure(fig)
    subplot(1,2,1)
    imagesc(image_lattice)
    daspect([1 1 1])
    colorbar

    subplot(1,2,2)
    imagesc(image_dmd)
    daspect([1 1 1])
    colorbar

    drawnow
end

%% Close Zelux
closeZelux(tlCameraSDK, tlCamera)