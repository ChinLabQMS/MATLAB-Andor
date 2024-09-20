%% Camera class test
clear
clc

c = Camera;
c.init
c.config('Exposure', 1)
c.startAcquisition
image = c.acquire;

figure
imagesc(image)
axis image
colorbar

c.close

%% AndorCamera class test
close all

c = AndorCamera(19330);
c.init
c.config('FastKinetic', 1)
c.startAcquisition
image = c.acquire;

figure
imagesc(image)
axis image
colorbar

%% AndorCameraConfig test
s = c.Config.struct;
AndorCameraConfig.struct2obj(s)

%% ZeluxCamera class test

close all

c = ZeluxCamera;
c.init
c.config('Exposure', 0.0001)
c.startAcquisition
image = c.acquire;

figure
imagesc(image)
axis image
colorbar

%% ZeluxCameraConfig test
s = c.Config.struct;
ZeluxCameraConfig.struct2obj(s)
