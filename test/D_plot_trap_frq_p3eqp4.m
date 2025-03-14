% Constants
wavelength = 1.064; % µm
k1 = 2 * pi / wavelength * [1, 0, 0];
k2 = 2 * pi / wavelength * [-1, 0, 0];
k3 = 2 * pi / wavelength * [0, -1, 0];
k4 = 2 * pi / wavelength * [0, 1, 0];
%k3 = 2 * pi / wavelength * [-sqrt(1/2), -sqrt(1/2), 0];
%k4 = 2 * pi / wavelength * [sqrt(1/2), sqrt(1/2), 0];
%P_range = 1:30; % Power range from 1 W to 15 W
P_range = linspace(4, 8, 50); 
w0 = 300; % µm
w1 = 150; % µm
P = 15;
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8; % Speed of light in vacuum (m/s)
m = 2.206e-25; % Mass of particle (Rubidium atom) in kg
alpha = -4.694e-30; % Proportionality constant

% Preallocate vector for frequency ratios
trap_frequency_ratios = zeros(1, length(P_range));

% Loop over P3 values to calculate trap frequencies
for i = 1:length(P_range)
    P3 = P_range(i);
    
    % Calculate electric fields E3 and E4
    E3 = 1e-3 * sqrt((4 * P3) / (pi * epsilon_0 * c * (w1 * 1e-6)^2));
    E4 = 1e-3 * sqrt((4 * P3) / (pi * epsilon_0 * c * (w1 * 1e-6)^2));
    
    % Calculate other electric fields E1 and E2 based on power
    E1 = 1e-3 * sqrt((4 * 2 * P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
    E2 = 1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
    % Define electric field components with Gaussian profile and linear polarization
    E1_field = @(x) E1 / 2 * gaussian_beam(transverse_distance(x, k1), w0) .* ...
        (exp(1i * (x * k1')) + exp(-1i * (x * k1')));
    
    E2_field = @(x) E2 / 2 * gaussian_beam(transverse_distance(x, k2), w0) .* ...
        (exp(1i * (x * k2')) + exp(-1i * (x * k2')));
    
    E3_field = @(x) E3 / 2 * gaussian_beam(transverse_distance(x, k3), w0) .* ...
        (exp(1i * (x * k3')) + exp(-1i * (x * k3')));
    
    E4_field = @(x) E4 / 2 * gaussian_beam(transverse_distance(x, k3), w0) .* ...
        (exp(1i * (x * k4')) + exp(-1i * (x * k4')));
    
        
    % Define functions for the Gaussian beam and electric fields
    gaussian_beam = @(r, w0) exp(-(r / w0).^2);
    transverse_distance = @(x, k) sqrt(sum(x.^2, 2) - (x * k').^2 / sum(k.^2));
    
    % 3D grid for calculations
    x_range = -1:0.01:1;
    y_range = -1:0.01:1;
    z_range = -1:0.01:1;
    [Y, X, Z] = meshgrid(y_range, x_range, z_range);
    coor = [X(:), Y(:), Z(:)];
    
    % Calculate intensity using electric fields
    % Total electric field and intensity
    E12_field = @(x) E1_field(x) + E2_field(x);
    E34_field = @(x) E3_field(x) + E4_field(x);
    I = @(x) 1/2 * epsilon_0 * c * (abs(E12_field(x)).^2 + abs(E34_field(x)).^2);


    %E12_field = @(x) E1 / 2 * gaussian_beam(transverse_distance(x, k1), w0) .* ...
    %    (exp(1i * (x * k1')) + exp(-1i * (x * k1'))) + ...
    %    E2 / 2 * gaussian_beam(transverse_distance(x, k2), w0) .* ...
    %    (exp(1i * (x * k2')) + exp(-1i * (x * k2')));
    
    %E34_field = @(x) E3 / 2 * gaussian_beam(transverse_distance(x, k3), w1) .* ...
    %    (exp(1i * (x * k3')) + exp(-1i * (x * k3'))) + ...
    %    E4 / 2 * gaussian_beam(transverse_distance(x, k4), w1) .* ...
    %    (exp(1i * (x * k4')) + exp(-1i * (x * k4')));
    
    % Intensity function
    %I = @(x) 1/2 * epsilon_0 * c * (abs(E12_field(x)).^2 + abs(E34_field(x)).^2);
    
    % Calculate intensity grid and reshape
    intensity = reshape(I(coor), length(x_range), length(y_range), length(z_range));
    [~, max_idx] = max(intensity(:));
    [x_max_idx, y_max_idx, z_max_idx] = ind2sub(size(intensity), max_idx);
    
    % Calculate second derivatives for Hessian at the maximum point
    dx = x_range(2) - x_range(1); % Assuming uniform spacing
    d2I_dx2 = (intensity(x_max_idx + 1, y_max_idx, z_max_idx) - ...
               2 * intensity(x_max_idx, y_max_idx, z_max_idx) + ...
               intensity(x_max_idx - 1, y_max_idx, z_max_idx)) / dx^2;
    d2I_dy2 = (intensity(x_max_idx, y_max_idx + 1, z_max_idx) - ...
               2 * intensity(x_max_idx, y_max_idx, z_max_idx) + ...
               intensity(x_max_idx, y_max_idx - 1, z_max_idx)) / dx^2;
    d2I_dxdy = (intensity(x_max_idx + 1, y_max_idx + 1, z_max_idx) - ...
                intensity(x_max_idx - 1, y_max_idx + 1, z_max_idx) - ...
                intensity(x_max_idx + 1, y_max_idx - 1, z_max_idx) + ...
                intensity(x_max_idx - 1, y_max_idx - 1, z_max_idx)) / (4 * dx^2);
    
    % Hessian matrix
    hessian_matrix = [d2I_dx2, d2I_dxdy; d2I_dxdy, d2I_dy2];
    eigenvalues = eig(hessian_matrix);
    
    % Calculate trap frequencies
    trap_frequencies = sqrt((alpha / m) * eigenvalues * 1e12) / (2 * pi); % Hz
    if trap_frequencies(2) ~= 0
        trap_frequency_ratios(i) = trap_frequencies(1) / trap_frequencies(2);
    end
end

% Plot the 2D graph of P3 versus the trap frequency ratio
figure;
plot(P_range, trap_frequency_ratios, '-o');
xlabel('I3 (W)');
ylabel('Trap Frequency Ratio (Major)');
title('Trap Frequency Ratio vs. I3');
grid on;