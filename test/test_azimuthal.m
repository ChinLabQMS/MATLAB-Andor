center = [100, 100];
[Y, X] = meshgrid((1:200) - center(1), (1:200) - center(2));
simulated = ((X.^2 + Y.^2) > 50^2) + ((X.^2 + Y.^2) > 100^2);

[val, x] = getAzimuthalAverage(simulated, center);
plot(x, val)

