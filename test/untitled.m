p = Preprocessor();
Signal = p.process(Data);
load("calibration/LatCalib.mat")

%%
signal = mean(Signal.Andor19331.Image, 3);
[signal, x_range, y_range] = prepareBox(signal, Andor19331.R, 150);

figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, signal)

subplot(1, 2, 2)
imagesc2(y_range, x_range, signal)
Andor19331.plot()
Andor19331.plotV()

sites = SiteGrid.prepareSite("Rect", "latx_range", -20:5:20, "laty_range", -20: 5: 20);
Andor19331.plot(sites, 'color', 'w', 'norm_radius', 0.5, 'filter', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])


%%

Zelux.calibrateR(Signal.Zelux.Pattern_532(:, :, 1))

figure
imagesc2(Signal.Zelux.Pattern_532(:, :, 1))
Zelux.plot()
Zelux.plotV()
