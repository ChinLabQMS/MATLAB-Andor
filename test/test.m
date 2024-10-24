clear; clc;

DataPath = 'data/2024/10 October/20241001/gray_on_black_anchor=3_triangle_side1=100_side2=150_r=20.mat';
PatternPath = 'C:\Users\qmspc\Documents\MATLAB\DMD-pattern-generator\resources\calib_anchor\white_on_black\anchor=3_triangle_side1=100_side2=150\template\r=20.bmp';

Data = load(DataPath, "Data").Data;
Signal = Preprocessor().processData(Data);

mean_Andor19330 = mean(Signal.Andor19330.Image, 3);
mean_Andor19331 = mean(Signal.Andor19331.Image, 3);
mean_Zelux = mean(Signal.Zelux.DMD, 3);
dmd = imread(PatternPath);

%%
figure
subplot(1, 3, 1)
Lattice.imagesc(mean_Andor19330)
subplot(1, 3, 2)
Lattice.imagesc(mean_Zelux)
subplot(1, 3, 3)
Lattice.imagesc(dmd)

%% Test pre-calibration

dmd_coor = [0, 0; 100, 0; 0, 150];
zelux_coor = [571, 646; 722, 501; 792, 870];

