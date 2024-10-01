p = Preprocessor;

p.init()

Data = load("data\2024\09 September\20240926 camera readout noise\FK2_typical_settings.mat").Data;
Signal = p.processData(Data);

%%
figure
imagesc(mean(Signal.Andor19330.Image, 3))
axis image
colorbar