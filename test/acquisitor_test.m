%% Acquisitor class test
clear; clc

c = Cameras();
a = Acquisitor(AcquisitionConfig(), c);
disp(a)

%%
a.config('NumAcquisitions', 5, 'Refresh', 0.1, 'Timeout', 10)
a.Cameras.Andor19330.config('FastKinetic', 1)
a.Cameras.Andor19331.config('Cropped', 1, 'XPixels', 100, 'YPixels', 100)
a.Cameras.Zelux.config('Exposure', 0.001)
a.Cameras.config('ExternalTrigger', 0)
a.init

a.acquire
a.run
a.acquire

%%
a.acquire2
a.acquire2

%% AcquisitionConfig class test

b = a.Config.struct;
AcquisitionConfig.struct2obj(b)

%% Dataset class test

d = a.Data;

d_struct = d.struct;
AcquisitionConfig.struct2obj(d_struct.AcquisitionConfig)
Dataset.struct2obj(d_struct)

%% Cameras class test
close all

c = Cameras.fromData(Data);
c.Andor19330.Config
c.Andor19331.Config
c.Zelux.Config

%%
Cameras.getStaticConfig(Data)