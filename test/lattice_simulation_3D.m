% Parameters
wavelength = 1.064;%mu m
k1 = 2 * pi / wavelength * [1, 0, 0];
k2 = 2 * pi / wavelength * [-1, 0, 0];
k3 = 2 * pi / wavelength * [-sqrt(1/2), -sqrt(1/2), 0];
P = 1; %W
% Beam waist (Gaussian beam)
w0 = 30;  %mu m
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8;               % Speed of light in vacuum (m/s)


% Calculate E1 in terms of power, permittivity, and speed of light
E1 = 6/7*1e-3*sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2));%V/mm
E2 = 6/7*1e-3*sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2));%V/mm
E3 = 9/7*1e-3*sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2));%V/mm



% Define a function to compute the transverse distance for each position vector in 3D
transverse_distance = @(x, k) sqrt(sum(x.^2, 2) - (x * k').^2 / sum(k.^2));

% Define electric field components with Gaussian profile and linear polarization
E1_field = @(x) E1 / 2 * gaussian_beam(transverse_distance(x, k1), w0) .* ...
    (exp(1i * (x * k1')) + exp(-1i * (x * k1')));

E2_field = @(x) E2 / 2 * gaussian_beam(transverse_distance(x, k2), w0) .* ...
    (exp(1i * (x * k2')) + exp(-1i * (x * k2')));

E3_field = @(x) E3 / 2 * gaussian_beam(transverse_distance(x, k3), w0) .* ...
    (exp(1i * (x * k3')) + exp(-1i * (x * k3')));

% The gaussian_beam function remains the same:
gaussian_beam = @(r, w0) exp(-(r / w0).^2);

% Total electric field with linear polarization
E_field = @(x) E1_field(x) + E2_field(x) + E3_field(x);
I = @(x) 1/2*epsilon_0 * c*abs(E_field(x)).^2;

% Define 3D grid
x_range = -2:0.01:2;
y_range = -2:0.01:2;
z_range = -2:0.01:2;
[Y, X, Z] = meshgrid(y_range, x_range, z_range);
coor = [X(:), Y(:), Z(:)];

% Calculate intensity and reshape for visualization
intensity = reshape(I(coor), length(x_range), length(y_range), length(z_range));

% Visualize intensity at specific z-planes
z_planes = [-4, 0, 4];  % Example z-planes to visualize

for z_idx = 1:length(z_planes)
    z_val = z_planes(z_idx);
    [~, z_pos] = min(abs(z_range - z_val));
    figure;
    imagesc(y_range, x_range, intensity(:, :, z_pos));
    axis image;
    title(['Intensity at z = ', num2str(z_val)]);
    colorbar;
end

% Define target points for intensity1 and intensity2
x_target1 = 0;
y_target1 = -0.75;
x_target2 = 0;
y_target2 = 0;

% Find closest indices in x_range and y_range for intensity1
[~, x_idx1] = min(abs(x_range - x_target1));
[~, y_idx1] = min(abs(y_range - y_target1));

% Get the intensity value at that point
intensity1 = intensity(x_idx1, y_idx1);
disp(['Intensity at (', num2str(x_target1), ', ', num2str(y_target1), ') is: ', num2str(intensity1)]);

% Find closest indices in x_range and y_range for intensity2
[~, x_idx2] = min(abs(x_range - x_target2));
[~, y_idx2] = min(abs(y_range - y_target2));

% Get the intensity value at that point
intensity2 = intensity(x_idx2, y_idx2);
disp(['Intensity at (', num2str(x_target2), ', ', num2str(y_target2), ') is: ', num2str(intensity2)]);

% Calculate |I1 - I2| * 0.34 * (10^-6); directly give muK result
trap_depth = abs(intensity1 - intensity2) * 0.34;
disp(['Result of |I1 - I2| * 0.34 in mu K is: ', num2str(trap_depth)]);

% Parameters for trap frequency calculation
m = 2.206e-25;  % Mass of particle (e.g., Rubidium atom) in kg
alpha = -4.694e-30; % Example proportionality constant

% Find the indices of the intensity maximum
[max_intensity, max_idx] = max(intensity(:));
[x_max_idx, y_max_idx, z_max_idx] = ind2sub(size(intensity), max_idx);

% Calculate the second derivative of intensity at the maximum point along x-axis
dx = x_range(2) - x_range(1);  % Assuming uniform grid spacing

% Numerical second derivative along x
d2I_dx2 = (intensity(x_max_idx + 1, y_max_idx, z_max_idx) ...
           - 2 * intensity(x_max_idx, y_max_idx, z_max_idx) ...
           + intensity(x_max_idx - 1, y_max_idx, z_max_idx)) / dx^2;

% Calculate the trap frequency
omega_trap = sqrt((alpha / m) * d2I_dx2*1e12);
trap_frequency_hz = omega_trap / (2 * pi);  % Convert from rad/s to Hz

% Display the trap frequency
%disp(['Trap frequency (omega) = ', num2str(omega_trap), ' rad/s']);
disp(['Trap frequency (f) = ', num2str(trap_frequency_hz), ' Hz']);