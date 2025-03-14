% Constants
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8;               % Speed of light in vacuum (m/s)
m = 2.206e-25;         % Mass of particle (e.g., Rubidium atom) in kg
alpha = -4.694e-30;    % Proportionality constant (J/(V/m)^2)

% Define ranges for P and w0
P_values = logspace(log10(0.1), log10(10), 20); % Power from 0.1 W to 10 W, log scale
w0_values = linspace(30, 300, 20); % Beam waist from 30 to 300 μm

% Initialize matrix for trap frequency results
trap_frequency_matrix = zeros(length(w0_values), length(P_values));

% Define x and y range for the grid (used for intensity and trap frequency calculation)
x_range = -2:0.01:2;
y_range = -2:0.01:2;

% Loop over each combination of P and w0
for i = 1:length(w0_values)
    w0 = w0_values(i); % Current beam waist in μm
    for j = 1:length(P_values)
        P = P_values(j); % Current power in W

        % Calculate E1 in terms of power, permittivity, and speed of light
        E1 = 1e-3 * sqrt((4 * (3*P/4)) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
        E2 = E1;
        E3 = 2*E1;

        % Define wave vectors
        k1 = 2 * pi / 1.064 * [1, 0, 0];
        k2 = 2 * pi / 1.064 * [-1, 0, 0];
        k3 = 2 * pi / 1.064 * [-sqrt(1/2), -sqrt(1/2), 0];

        % Define Gaussian profile function
        gaussian_beam = @(r, w0) exp(-(r / w0).^2);

        % Define electric field components
        E1_field = @(x) E1 / 2 * gaussian_beam(sqrt(x(:,2).^2 + x(:,3).^2), w0) .* ...
            (exp(1i * (x * k1')) + exp(-1i * (x * k1')));
        E2_field = @(x) E2 / 2 * gaussian_beam(sqrt(x(:,2).^2 + x(:,3).^2), w0) .* ...
            (exp(1i * (x * k2')) + exp(-1i * (x * k2')));
        E3_field = @(x) E3 / 2 * gaussian_beam(sqrt(x(:,2).^2 + x(:,3).^2), w0) .* ...
            (exp(1i * (x * k3')) + exp(-1i * (x * k3')));

        % Total electric field
        E_field = @(x) E1_field(x) + E2_field(x) + E3_field(x);
        I = @(x) 1/2 * epsilon_0 * c * abs(E_field(x)).^2;

        % Define coordinate grid
        [Y, X] = meshgrid(y_range, x_range);
        coor = [X(:), Y(:), zeros(numel(X), 1)];

        % Calculate intensity and reshape for visualization
        intensity = reshape(I(coor), length(x_range), length(y_range));

        % Find the intensity maximum and calculate the second derivative
        [max_intensity, max_idx] = max(intensity(:));
        [x_max_idx, y_max_idx] = ind2sub(size(intensity), max_idx);

        % Calculate the second derivative of intensity at the maximum point along x-axis
        dx = x_range(2) - x_range(1);  % Assuming uniform grid spacing
        if x_max_idx > 1 && x_max_idx < length(x_range) % ensure the index is within bounds
            d2I_dx2 = (intensity(x_max_idx + 1, y_max_idx) ...
                      - 2 * intensity(x_max_idx, y_max_idx) ...
                      + intensity(x_max_idx - 1, y_max_idx)) / dx^2;

            % Calculate the trap frequency
            omega_trap = sqrt((alpha / m) * d2I_dx2 * 1e12); % 1e12 factor for unit adjustment
            trap_frequency_matrix(i, j) = omega_trap / (2 * pi); % Convert from rad/s to Hz
        else
            trap_frequency_matrix(i, j) = NaN; % Handle boundary cases
        end
    end
end

% Plot the trap frequency as a function of P and w0 with contour lines
figure;
imagesc(log10(P_values), w0_values, trap_frequency_matrix);
colorbar;
title('Trap Frequency (Hz)');
xlabel('Log10(Power, W)');
ylabel('Beam Waist w_0 (\mum)');
set(gca, 'YDir', 'normal'); % Correct orientation

% Adjust the colormap and color limits
colormap('jet'); % Use a more colorful colormap
caxis([min(trap_frequency_matrix(:)), max(trap_frequency_matrix(:))]); % Set color axis to data range

% Add white contour lines at specific trap frequency values
hold on;
contour(log10(P_values), w0_values, trap_frequency_matrix, [50000, 100000], 'LineColor', 'w', 'LineWidth', 1.5);
hold off;