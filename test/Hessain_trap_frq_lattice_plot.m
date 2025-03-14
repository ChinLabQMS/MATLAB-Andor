% Parameters
wavelength = 1.064; % μm
k1 = 2 * pi / wavelength * [1, 0, 0];
k2 = 2 * pi / wavelength * [-1, 0, 0];
k3 = 2 * pi / wavelength * [0, -1, 0];
k4 = 2 * pi / wavelength * [0, 1, 0];
P = 15; % W
P_3 = 3.714; % W
w0 = 300; % μm (beam waist)
w1 = 150; % μm (beam waist for beams 3 and 4)
epsilon_0 = 8.854e-12; % F/m (permittivity of free space)
c = 3e8; % m/s (speed of light)

% Calculate electric field amplitudes for each beam
E1 = 1e-3 * sqrt((4 *2* P) / (pi * epsilon_0 * c * (w0*1e-6)^2)); % V/mm
E2 = 1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2)); % V/mm
E3 = 1e-3 * sqrt((4 * P_3) / (pi * epsilon_0 * c * (w1*1e-6)^2)); % V/mm
E4 = 1e-3 * sqrt((4 * 2*P_3) / (pi * epsilon_0 * c * (w1*1e-6)^2)); % V/mm

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

%E12_field = @(x) E1_field(x) + E2_field(x);
%E34_field = @(x) E3_field(x) + E4_field(x);
%I = @(x) 1/2 * epsilon_0 * c * (abs(E12_field(x)).^2 + abs(E34_field(x)).^2);

% Define 3D grid
x_range = -2:0.01:2;
y_range = -2:0.01:2;
z_range = -2:0.01:2;
[Y, X, Z] = meshgrid(y_range, x_range, z_range);
coor = [X(:), Y(:), Z(:)];

% Calculate intensity and reshape for visualization
intensity = reshape(I(coor), length(x_range), length(y_range), length(z_range));

% Target points
x_target1 = 0;
y_target1 = 0.27;
x_target2 = 0;
y_target2 = 0;
% Find closest indices for target points
[~, x_idx1] = min(abs(x_range - x_target1));
[~, y_idx1] = min(abs(y_range - y_target1));
[~, x_idx2] = min(abs(x_range - x_target2));
[~, y_idx2] = min(abs(y_range - y_target2));

% Get intensities at the target points
intensity1 = intensity(x_idx1, y_idx1);
intensity2 = intensity(x_idx2, y_idx2);

% Calculate trap depth and store in matrix
trap_depth_matrix = abs(intensity1 - intensity2) * 0.34; % in μK
% Find the indices of the intensity maximum
[max_intensity, max_idx] = max(intensity(:));
[x_max_idx, y_max_idx, z_max_idx] = ind2sub(size(intensity), max_idx);

% Calculate second derivatives of intensity at the maximum point along x and y axes
dx = x_range(2) - x_range(1); % Assuming uniform grid spacing

% Numerical second derivatives along x and y
d2I_dx2 = (intensity(x_max_idx + 1, y_max_idx, z_max_idx) ...
           - 2 * intensity(x_max_idx, y_max_idx, z_max_idx) ...
           + intensity(x_max_idx - 1, y_max_idx, z_max_idx)) / dx^2;
d2I_dy2 = (intensity(x_max_idx, y_max_idx + 1, z_max_idx) ...
           - 2 * intensity(x_max_idx, y_max_idx, z_max_idx) ...
           + intensity(x_max_idx, y_max_idx - 1, z_max_idx)) / dx^2;
d2I_dxdy = (intensity(x_max_idx + 1, y_max_idx + 1, z_max_idx) ...
            - intensity(x_max_idx - 1, y_max_idx + 1, z_max_idx) ...
            - intensity(x_max_idx + 1, y_max_idx - 1, z_max_idx) ...
            + intensity(x_max_idx - 1, y_max_idx - 1, z_max_idx)) / (4 * dx^2);

% Construct the Hessian matrix
hessian_matrix = [d2I_dx2, d2I_dxdy; d2I_dxdy, d2I_dy2];

% Find eigenvalues and eigenvectors for the Hessian matrix
[eigenvectors, eigenvalues_matrix] = eig(hessian_matrix);
eigenvalues = diag(eigenvalues_matrix);

% Calculate trap frequencies along the major and minor axes
m = 2.206e-25;  % Mass of particle in kg
alpha = -4.694e-30; % Example proportionality constant
trap_frequencies = sqrt((alpha / m) * eigenvalues * 1e12) / (2 * pi);  % Convert rad/s to Hz

% Display trap frequencies
disp(['Trap depth: ', num2str(trap_depth_matrix), ' Hz']);

disp(['Trap frequency along major axis: ', num2str(trap_frequencies(1)), ' Hz']);
disp(['Trap frequency along minor axis: ', num2str(trap_frequencies(2)), ' Hz']);
disp('Major and minor axis orientation:');
disp(eigenvectors);

% Plot the intensity map at z = 0 with the major and minor axis orientation
[~, z_pos] = min(abs(z_range)); % Choose z = 0 plane
figure;
imagesc(y_range, x_range, intensity(:, :, z_pos));
axis image;
colormap(jet);
colorbar;
hold on;

% Overlay the major and minor axis orientation
quiver(0, 0, eigenvectors(2, 1),eigenvectors(1, 1), 'r', 'LineWidth', 2, 'DisplayName', 'Minor Axis');
quiver(0, 0, eigenvectors(2, 2), eigenvectors(1, 2), 'b', 'LineWidth', 2, 'DisplayName', 'Major Axis');

% Label the plot
xlabel('Y-axis (\mum)');
ylabel('X-axis (\mum)');
title('Intensity Map at z = 0 with Major and Minor Axis Orientation');
legend;
grid on;
hold off;