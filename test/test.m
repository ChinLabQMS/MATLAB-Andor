Signal = Preprocessor().processData(Data);

mean_img = mean(Signal.Andor19330.Image, 3);

Lattice.imagesc(mean_img)
