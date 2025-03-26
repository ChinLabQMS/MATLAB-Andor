Data = load("data/2025/03 March/20250325/dense_calibration4.mat").Data;

%%
Signal = Preprocessor().process(Data);
calib1 = load("calibration/dated_LatCalib/LatCalib_20250325.mat");
calib2 = load("calibration/dated_LatCalib/LatCalib_20250325_204026.mat");
template = imread("resources/pattern_line/gray_square_on_black_spacing=150/template/width=5.bmp");

%%
figure
imagesc2(Signal.Andor19330.Image(:, :, 1))
calib1.Andor19330.plot('color', 'r')
calib2.Andor19330.plot('color', 'w')
calib2.Andor19330.plotV()

%%
figure
imagesc2(Signal.Andor19331.Image(:, :, 1))
calib1.Andor19331.plot('color', 'r')
calib2.Andor19331.plot('color', 'w')
calib2.Andor19331.plotV()

%%
figure
imagesc2(Signal.Zelux.Lattice_935(:, :, 1))
calib1.Zelux.plot('color', 'r')
calib2.Zelux.plot('color', 'w')
calib2.Zelux.plotV()

%%
figure
imagesc2(template)
calib1.DMD.plot('color', 'r')
calib2.DMD.plot('color', 'w')
calib2.DMD.plotV()

%%
dmd = Projector();
dmd.open()

%%
dmd.MexHandle("resetPattern", 0xFF000000)

line_center = calib2.DMD.R + calib2.DMD.V2 .* [-20, -15, -10, -5, 0, 5, 10, 15, 20]';
for i = 1: size(line_center, 1)
    R = line_center(i, :);
    dmd.drawLinesAlongVector(calib2.DMD.V1, R, "line_color", 0xFFAAAAAA, "line_width", 5)
end

%%
sites = [0, 0; -2, 0; 2, 0; 0, -2; 0, 2; 2, 2; -2, -2];
dmd.drawCirclesOnSite(calib2.DMD, sites)

%%
dmd.MexHandle("resetPattern", 0xFF000000)
dmd.drawLineAlongVector(DMD.V3, DMD.R, 'line_color', 0xFFAAAAAA, 'line_width', 5)

%%
figure
imagesc2(dmd.MexHandle("getRealCanvasRGB"))
calib2.DMD.plot()
calib2.DMD.plotV()

%%
dmd.MexHandle("selectAndSavePatternAsBMP")

%%
dmd.close()

%%
pat = imread("data/2025/03 March/20250325/template/circle_array_python.bmp");

figure
imagesc2(pat)
calib2.DMD.plot()
