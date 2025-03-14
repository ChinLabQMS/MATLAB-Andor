% Constants
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8;               % Speed of light in vacuum (m/s)
m = 2.206e-25;         % Mass of particle (e.g., Rubidium atom) in kg
alpha = -4.694e-30;    % Proportionality constant (J/(V/m)^2)

% Define ranges for P and w0
P_values = logspace(log10(0.1), log10(10), 20); % Power from 0.1 W to 10 W, log scale
w0_values = linspace(30, 300, 20); % Beam waist from 30 to 300 μm

% Initialize matrices for each configuration
trap_depth_matrix_default = zeros(length(w0_values), length(P_values));
trap_frequency_matrix_default = zeros(length(w0_values), length(P_values));

trap_depth_matrix_yellow = zeros(length(w0_values), length(P_values));
trap_frequency_matrix_yellow = zeros(length(w0_values), length(P_values));

trap_depth_matrix_red = zeros(length(w0_values), length(P_values));
trap_frequency_matrix_red = zeros(length(w0_values), length(P_values));

trap_depth_matrix_green = zeros(length(w0_values), length(P_values));
trap_frequency_matrix_green = zeros(length(w0_values), length(P_values));


% Define x and y range for the grid
x_range = -2:0.01:2;
y_range = -2:0.01:2;

% Loop over each configuration of P and w0
for config = 1:4
    trap_depth_matrix = zeros(length(w0_values), length(P_values));
    trap_frequency_matrix = zeros(length(w0_values), length(P_values));

    for i = 1:length(w0_values)
        w0 = w0_values(i); % Current beam waist in μm
        for j = 1:length(P_values)
            P = P_values(j); % Current power in W

            % Set E1, E2, and E3 based on the configuration
            if config == 1
                % Default configuration
                E1 = 1e-3 * sqrt((4 *2* P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
                E2 = E1/2;
                E3 = E1;
            elseif config == 2
                % Yellow configuration
                E1 = 3/4*1e-3 * sqrt((4 * 2* P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
                E2 = E1/2;
                E3 = 2 * E1;
            elseif config == 3
                % Red configuration
                E1 = 6/7*1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
                E2 = E1;
                E3 = 3/2 * E1;
            elseif config == 4
                % Red configuration
                E1 = 3/5*1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
                E2 = E1;
                E3 = 3 * E1;
            end

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

            % Calculate trap depth (difference in intensity)
            intensity1 = intensity(x_range == 0, y_range == -0.75);
            intensity2 = intensity(x_range == 0, y_range == 0);
            trap_depth_matrix(i, j) = abs(intensity1 - intensity2) * 0.34; % in μK

            % Calculate trap frequency at the maximum intensity point
            [~, max_idx] = max(intensity(:));
            [x_max_idx, y_max_idx] = ind2sub(size(intensity), max_idx);

            % Calculate second derivative along x-axis at the maximum point
            dx = x_range(2) - x_range(1);
            if x_max_idx > 1 && x_max_idx < length(x_range)
                d2I_dx2 = (intensity(x_max_idx + 1, y_max_idx) ...
                          - 2 * intensity(x_max_idx, y_max_idx) ...
                          + intensity(x_max_idx - 1, y_max_idx)) / dx^2;
                omega_trap = sqrt((alpha / m) * d2I_dx2 * 1e12);
                trap_frequency_matrix(i, j) = omega_trap / (2 * pi);
            else
                trap_frequency_matrix(i, j) = NaN;
            end
        end
    end

    % Store matrices for each configuration
    if config == 1
        trap_depth_matrix_default = trap_depth_matrix;
        trap_frequency_matrix_default = trap_frequency_matrix;
    elseif config == 2
        trap_depth_matrix_yellow = trap_depth_matrix;
        trap_frequency_matrix_yellow = trap_frequency_matrix;
    elseif config == 3
        trap_depth_matrix_red = trap_depth_matrix;
        trap_frequency_matrix_red = trap_frequency_matrix;
    elseif config == 4
        trap_depth_matrix_green = trap_depth_matrix;
        trap_frequency_matrix_green = trap_frequency_matrix;
    end
end

% Plot the trap depth for the default configuration
figure;
imagesc(log10(P_values), w0_values, trap_depth_matrix_default);
colorbar;
title('Trap Depth (\muK)');
xlabel('Power (W)');
ylabel('Beam Waist w_0 (\mum)');
set(gca, 'YDir', 'normal');
colormap('jet');
caxis([min(trap_depth_matrix_default(:)), max(trap_depth_matrix_default(:))]);

% Define custom x-ticks
real_xticks = [0.1, 0.2, 0.4, 0.8, 1.4, 2.6, 5.2, 10];
log_xticks = log10(real_xticks); % Convert these values to log10 scale for plotting
set(gca, 'XTick', log_xticks, 'XTickLabel', arrayfun(@num2str, real_xticks, 'UniformOutput', false)); % Set both position and labels

% Add contour lines for trap depth (white) and trap frequency (dashed white) for default configuration
hold on;
contour(log10(P_values), w0_values, trap_depth_matrix_default, [100, 500, 1000], 'LineColor', 'w', 'LineWidth', 1.5);
contour(log10(P_values), w0_values, trap_frequency_matrix_default, [50000, 100000], 'LineColor', 'w', 'LineStyle', '--', 'LineWidth', 1.5);

% Add yellow contour lines for trap depth and trap frequency (yellow configuration)
contour(log10(P_values), w0_values, trap_depth_matrix_yellow, [100, 500, 1000], 'LineColor', 'y', 'LineWidth', 1.5);
contour(log10(P_values), w0_values, trap_frequency_matrix_yellow, [50000, 100000], 'LineColor', 'y', 'LineStyle', '--', 'LineWidth', 1.5);

% Add red contour lines for trap depth and trap frequency (red configuration)
%contour(log10(P_values), w0_values, trap_depth_matrix_red, [100, 500, 1000], 'LineColor', 'r', 'LineWidth', 1.5);
%contour(log10(P_values), w0_values, trap_frequency_matrix_red, [50000, 100000], 'LineColor', 'r', 'LineStyle', '--', 'LineWidth', 1.5);

% Add red contour lines for trap depth and trap frequency (red configuration)
%contour(log10(P_values), w0_values, trap_depth_matrix_green, [100, 500, 1000], 'LineColor', 'g', 'LineWidth', 1.5);
%contour(log10(P_values), w0_values, trap_frequency_matrix_green, [50000, 100000], 'LineColor', 'g', 'LineStyle', '--', 'LineWidth', 1.5);

hold off;