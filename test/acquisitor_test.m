%% Acquisitor class test
clear; clc

cameras = Cameras("test_mode", true);
% cameras = Cameras();
config = AcquisitionConfig();
a = Acquisitor(config, cameras);
disp(a)

%%
a.config('NumAcquisitions', 5, 'Refresh', 0.1, 'Timeout', 10)
a.initCameras
a.Cameras.Andor19330.config('FastKinetic', 1)
a.Cameras.Andor19331.config('Cropped', 1, 'XPixels', 100, 'YPixels', 100)
a.Cameras.Zelux.config('Exposure', 0.001)
a.Cameras.config('ExternalTrigger', 0)
a.init

a.acquire
a.run
a.acquire

%% AcquisitionConfig class test

b = a.Config.struct;
AcquisitionConfig.struct2obj(b)
AcquisitionConfig.struct2obj(b).SequenceTable

%% Dataset class test

d = a.Data;

d_struct = d.struct;
d_reload = Dataset.struct2obj(d_struct);
disp(d_reload)
