%%
clear; clc;
p = LatPreCalibGenerator;

%%
p.config("DataPath", "data/2024/09 September/20240930 multilayer/FK2_focused_to_major_layer.mat")
p.init()

%%
close all
p.plot("Andor19330")

%%
p.calibrate("Andor19330", [105, 188; 156, 223; 212, 196])

%%
close all
p.plot("Andor19331")

%%
p.calibrate("Andor19331", [92, 165; 123, 216; 178, 212])

%%
close all
p.plot("Zelux")

%%
p.calibrate("Zelux", [547, 566; 598, 595; 651, 571])

%%
p.save()