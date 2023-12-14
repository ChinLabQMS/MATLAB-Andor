%% Initialize Zelux camera
[tlCameraSDK, tlCamera] = initializeZelux();

%% Acquire images from Zelux
image = acquireZeluxImage(tlCamera);

figure
imagesc(image)
daspect([1 1 1])
colorbar

%% Close Zelux
closeZelux(tlCameraSDK, tlCamera)