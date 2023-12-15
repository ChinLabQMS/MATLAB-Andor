initializeCCD()
setCurrentCCD(19330)

% setDataLive1(exposure=0.01)
setDataLiveFK(exposure=0.01, external_trigger=false, num_frames=8)
image = acquireCCDImage();

figure
imagesc(image)
daspect([1 1 1])
colorbar