% Parameters
wavelength = 1.064; % μm
k1 = 2 * pi / wavelength * [1, 0, 0];
k2 = 2 * pi / wavelength * [-1, 0, 0];
k3 = 2 * pi / wavelength * [-sqrt(1/2), -sqrt(1/2), 0];
k4 = 2 * pi / wavelength * [sqrt(1/2), sqrt(1/2), 0];
P = 15; % W
P_3 = 5; % W
w0 = 300; % μm (beam waist)
w1 = 150; % μm (beam waist for beams 3 and 4)
epsilon_0 = 8.854e-12; % F/m (permittivity of free space)
c = 3e8; % m/s (speed of light)

% Calculate electric field amplitudes for each beam
E1 = 1e-3 * sqrt((4 * 2 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2)); % V/mm
E2 = 1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2)); % V/mm
E3 = 1e-3 * sqrt((4 * P_3) / (pi * epsilon_0 * c * (w1*1e-6)^2)); % V/mm
E4 = 1e-3 * sqrt((4 * P_3) / (pi * epsilon_0 * c * (w1*1e-6)^2)); % V/mm

% Define Gaussian beam function
gaussian_beam = @(r, w0) exp(-(r / w0).^2);

% Define a function to compute transverse distance
transverse_distance = @(x, k) sqrt(sum(x.^2, 2) - (x * k').^2 / sum(k.^2));

% Define electric field components with Gaussian profile and linear polarization
E1_field = @(x) E1 / 2 * gaussian_beam(transverse_distance(x, k1), w0) .* ...
    (exp(1i * (x * k1')) + exp(-1i * (x * k1')));
E2_field = @(x) E2 / 2 * gaussian_beam(transverse_distance(x, k2), w0) .* ...
    (exp(1i * (x * k2')) + exp(-1i * (x * k2')));
E3_field = @(x) E3 / 2 * gaussian_beam(transverse_distance(x, k3), w1) .* ...
    (exp(1i * (x * k3')) + exp(-1i * (x * k3')));
E4_field = @(x) E4 / 2 * gaussian_beam(transverse_distance(x, k4), w1) .* ...
    (exp(1i * (x * k4')) + exp(-1i * (x * k4')));

% Total electric field and intensity
E12_field = @(x) E1_field(x) + E2_field(x);
E34_field = @(x) E3_field(x) + E4_field(x);
I = @(x) 1/2 * epsilon_0 * c * (abs(E12_field(x)).^2 + abs(E34_field(x)).^2);

% Define 2D grid (for a single z-plane, as this is a 2D Fourier transform)
x_range = -2:0.01:2;
y_range = -2:0.01:2;
[Y, X] = meshgrid(y_range, x_range);
coor = [X(:), Y(:), zeros(numel(X), 1)];

% Calculate intensity at z = 0 and reshape for visualization
intensity_2D = reshape(I(coor), length(x_range), length(y_range));

% Perform 2D Fourier Transform
F = fftshift(fft2(intensity_2D));
F_magnitude = abs(F);

% Find dominant frequencies in the Fourier transform
[~, max_idx] = max(F_magnitude(:));
[fx_idx, fy_idx] = ind2sub(size(F_magnitude), max_idx);

% Convert indices to frequency directions
fx = fx_idx - (size(F_magnitude, 1) / 2 + 1);
fy = fy_idx - (size(F_magnitude, 2) / 2 + 1);

% Normalize to unit vectors for direction
major_axis = [fx, fy] / norm([fx, fy]);
minor_axis = [-major_axis(2), major_axis(1)]; % Perpendicular to major axis

% Find the indices of the intensity maximum
[max_intensity, max_idx] = max(intensity_2D(:));
[x_max_idx, y_max_idx] = ind2sub(size(intensity_2D), max_idx);

% Calculate second derivatives of intensity along major and minor axes
dx = x_range(2) - x_range(1); % Assuming uniform grid spacing

% Project the second derivatives onto the major and minor axes
d2I_major = (intensity_2D(x_max_idx + round(major_axis(1)), y_max_idx + round(major_axis(2))) ...
           - 2 * intensity_2D(x_max_idx, y_max_idx) ...
           + intensity_2D(x_max_idx - round(major_axis(1)), y_max_idx - round(major_axis(2)))) / dx^2;

d2I_minor = (intensity_2D(x_max_idx + round(minor_axis(1)), y_max_idx + round(minor_axis(2))) ...
           - 2 * intensity_2D(x_max_idx, y_max_idx) ...
           + intensity_2D(x_max_idx - round(minor_axis(1)), y_max_idx - round(minor_axis(2)))) / dx^2;

% Calculate trap frequencies along the major and minor axes
m = 2.206e-25;  % Mass of particle in kg (e.g., Rubidium atom)
alpha = -4.694e-30; % Example proportionality constant
trap_frequency_major = sqrt((alpha / m) * d2I_major * 1e12) / (2 * pi);  % Hz
trap_frequency_minor = sqrt((alpha / m) * d2I_minor * 1e12) / (2 * pi);  % Hz

% Display trap frequencies
disp(['Trap frequency along major axis: ', num2str(trap_frequency_major), ' Hz']);
disp(['Trap frequency along minor axis: ', num2str(trap_frequency_minor), ' Hz']);

% Plot the intensity map with major and minor axis orientation
figure;
imagesc(y_range, x_range, intensity_2D);
axis image;
colormap(jet);
colorbar;
hold on;

% Overlay the major and minor axis orientation
quiver(0, 0, major_axis(1), major_axis(2), 'r', 'LineWidth', 2, 'DisplayName', 'Major Axis');
quiver(0, 0, minor_axis(1), minor_axis(2), 'b', 'LineWidth', 2, 'DisplayName', 'Minor Axis');

% Label the plot
xlabel('Y-axis (\mum)');
ylabel('X-axis (\mum)');
title('Intensity Map with Fourier-Derived Major and Minor Axis Orientation');
legend;
grid on;
hold off;