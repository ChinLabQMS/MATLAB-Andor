p = Preprocessor();
Signal = p.process(Data);

%%

index = 1;
signal = Signal.Andor19330.Image(:, :, index);

%%
Andor19330.calibrateR(signal(1:512,:))

%%
figure
imagesc(signal)
daspect([1 1 1])
colorbar
Andor19330.plot()
