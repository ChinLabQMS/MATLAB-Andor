%% Acquisitor class test
clear; clc

a = Acquisitor();
disp(a)

a.config('NumAcquisitions', 5)
a.Cameras.Andor19330.config('FastKinetic', 1)
a.Cameras.Andor19331.config('Cropped', 1, 'XPixels', 100, 'YPixels', 100)
a.init

a.acquire
a.run
a.acquire

%% AcquisitionConfig class test

b = a.Config.struct;
AcquisitionConfig.struct2obj(b)

%% Dataset class test

d = a.Data;
d_struct = d.struct;
AcquisitionConfig.struct2obj(d_struct.AcquisitionConfig)
Dataset.struct2obj(d_struct)

%% Cameras class test

c = Cameras.fromData(d_struct);
c
