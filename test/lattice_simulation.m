%% Consider only scalar electric field

wavelength = 0.935;
k1 = 2*pi/wavelength * [1, 0, 0];
E1 = 1;

k2 = 2*pi/wavelength * [-1, 0, 0];
E2 = 1;

E1_field = @(x) E1/2 *(exp(1i * k1 * x') + exp(-1i * k1 * x'));
E2_field = @(x) E2/2 * (exp(1i * k2 * x') + exp(-1i * k2 * x'));

E_field = @(x) E1_field(x) + E2_field(x);
I = @(x) abs(E_field(x)).^2;

x_range = -5: 0.01: 5;
y_range = -5: 0.01: 5;
[Y, X] = meshgrid(y_range, x_range);
coor = [X(:), Y(:)];

intensity = reshape(I(coor), length(x_range), length(y_range));

%%
figure
imagesc(y_range, x_range, intensity)
