% Constants
wavelength = 1.064; % µm
k1 = 2 * pi / wavelength * [1, 0, 0];
k2 = 2 * pi / wavelength * [-1, 0, 0];
%k3 = 2 * pi / wavelength * [-sqrt(1/2), -sqrt(1/2), 0];
%k4 = 2 * pi / wavelength * [sqrt(1/2), sqrt(1/2), 0];
k3 = 2 * pi / wavelength * [0, -1, 0];
k4 = 2 * pi / wavelength * [0, 1, 0];
P = 15;
P_range = 1:15; % Power range from 1 W to 50 W
%P_range = linspace(1, 50, 10); 
%P_range = linspace(6, 10, 20); 
w0 = 300; % µm
w1 = 150; % µm
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8; % Speed of light in vacuum (m/s)
m = 2.206e-25; % Mass of particle (Rubidium atom) in kg
alpha = -4.694e-30; % Proportionality constant

% Preallocate matrix for frequency ratios
trap_frequency_ratios = zeros(length(P_range), length(P_range));
trap_frequencies_2 = zeros(length(P_range), length(P_range));
% Loop over P3 and P4 values to calculate trap frequencies
for i = 1:length(P_range)
    for j = 1:length(P_range)
        P3 = P_range(i);
        P4 = P_range(j);
        
        % Calculate electric fields E3 and E4
        E3 = 1e-3 * sqrt((4 * P3) / (pi * epsilon_0 * c * (w1 * 1e-6)^2));
        E4 = 1e-3 * sqrt((4 * P4) / (pi * epsilon_0 * c * (w1 * 1e-6)^2));
        % Calculate E1 in terms of power, permittivity, and speed of light
        E1 = 1e-3*sqrt((4 * 2*P) / (pi * epsilon_0 * c * (w0*1e-6)^2));%V/mm
        E2 = 1e-3*sqrt((4 * P) / (pi * epsilon_0 * c * (w0*1e-6)^2));%V/mm
        
        % Define a function to compute the transverse distance for each position vector in 3D
        transverse_distance = @(x, k) sqrt(sum(x.^2, 2) - (x * k').^2 / sum(k.^2));
        
        % Define electric field components with Gaussian profile and linear polarization
        E1_field = @(x) E1 / 2 * gaussian_beam(transverse_distance(x, k1), w0) .* ...
            (exp(1i * (x * k1')) + exp(-1i * (x * k1')));
        
        E2_field = @(x) E2 / 2 * gaussian_beam(transverse_distance(x, k2), w0) .* ...
            (exp(1i * (x * k2')) + exp(-1i * (x * k2')));
        
        E3_field = @(x) E3 / 2 * gaussian_beam(transverse_distance(x, k3), w0) .* ...
            (exp(1i * (x * k3')) + exp(-1i * (x * k3')));
        
        E4_field = @(x) E4 / 2 * gaussian_beam(transverse_distance(x, k3), w0) .* ...
            (exp(1i * (x * k4')) + exp(-1i * (x * k4')));
        
        % The gaussian_beam function remains the same:
        gaussian_beam = @(r, w0) exp(-(r / w0).^2);
        
        % Total electric field with linear polarization
        %E12_field = @(x) E1_field(x) + E2_field(x);
        %E34_field = @(x) E3_field(x) + E4_field(x);
        %I = @(x) 1/2*epsilon_0 * c*(abs(E12_field(x)).^2+abs(E34_field(x)).^2);
        % Total electric field and intensity
        E12_field = @(x) E1_field(x) + E2_field(x);
        E34_field = @(x) E3_field(x) + E4_field(x);
        I = @(x) 1/2 * epsilon_0 * c * (abs(E12_field(x)).^2 + abs(E34_field(x)).^2);


        % Define 3D grid
        x_range = -1:0.01:1;
        y_range = -1:0.01:1;
        z_range = -1:0.1:1;
        [Y, X, Z] = meshgrid(y_range, x_range, z_range);
        coor = [X(:), Y(:), Z(:)];
        
        % Calculate intensity and reshape for visualization
        intensity = reshape(I(coor), length(x_range), length(y_range), length(z_range));

        % Find the indices of the intensity maximum
        [max_intensity, max_idx] = max(intensity(:));
        [x_max_idx, y_max_idx, z_max_idx] = ind2sub(size(intensity), max_idx);
        
        % Calculate second derivatives of intensity at the maximum point along x and y axes
        dx = x_range(2) - x_range(1);  % Assuming uniform grid spacing
        
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
        trap_frequencies = sqrt((alpha / m) * eigenvalues * 1e12) / (2 * pi);  % Convert rad/s to Hz

      
        if trap_frequencies(2) ~= 0
            trap_frequency_ratios(i, j) = trap_frequencies(1)/trap_frequencies(2);
        end
        trap_frequencies_2(i, j) = trap_frequencies(2);
    end
end

% Plot the trap frequency ratio as a function of I3 and I4 with contour lines
figure;

% Display the color plot for trap_frequency_ratios
imagesc(P_range, P_range, trap_frequency_ratios);
colorbar;
title('Trap Frequency Ratio (Minor/Major Axis)');
xlabel('I4 (W)');
ylabel('I3 (W)');
set(gca, 'YDir', 'normal'); % Ensure correct y-axis orientation

% Adjust the colormap and color limits
colormap('jet'); % Use a more colorful colormap
caxis([min(trap_frequency_ratios(:)), max(trap_frequency_ratios(:))]); % Set color axis to data range

% Overlay white contour lines for specific trap frequency ratios
hold on;
levels = [1.02,1.001]; % Define specific levels for trap_frequency_ratios
contour(P_range, P_range, trap_frequency_ratios, levels, 'LineColor', 'w', 'LineWidth', 1.5);

% Overlay dashed contour lines for specific trap_frequencies_2
trap_frequency_levels = [120000, 150000]; % Example trap frequency levels in Hz
contour(P_range, P_range, trap_frequencies_2, trap_frequency_levels, ...
    'LineColor', 'w', 'LineStyle', '--', 'LineWidth', 1.5);

hold off;