% Constants
epsilon_0 = 8.854e-12; % Permittivity of free space (F/m)
c = 3e8;               % Speed of light in vacuum (m/s)

% Define ranges for P and w0
P_values = logspace(log10(0.1), log10(10), 20); % Power from 0.1 W to 10 W, log scale
w0_values = linspace(30, 300, 20); % Beam waist from 30 to 300 μm

% Initialize matrix for trap depth results
trap_depth_matrix = zeros(length(w0_values), length(P_values));

% Target points
x_target1 = -0.75;
y_target1 = 0;
x_target2 = 0;
y_target2 = 0;

% Define x and y range for the grid
x_range = -2:0.01:2;
y_range = -2:0.01:2;

% Loop over each combination of P and w0
for i = 1:length(w0_values)
    w0 = w0_values(i); % Current beam waist in μm
    for j = 1:length(P_values)
        P = P_values(j); % Current power in W

        % Calculate E1 in terms of power, permittivity, and speed of light
        E1 = 1e-3 * sqrt((4 * P) / (pi * epsilon_0 * c * (w0 * 1e-6)^2)); % V/mm
        E2 = E1;
        E3 = E1;

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

        % Find closest indices for target points
        [~, x_idx1] = min(abs(x_range - x_target1));
        [~, y_idx1] = min(abs(y_range - y_target1));
        [~, x_idx2] = min(abs(x_range - x_target2));
        [~, y_idx2] = min(abs(y_range - y_target2));

        % Get intensities at the target points
        intensity1 = intensity(x_idx1, y_idx1);
        intensity2 = intensity(x_idx2, y_idx2);

        % Calculate trap depth and store in matrix
        trap_depth_matrix(i, j) = abs(intensity1 - intensity2) * 0.34; % in μK
    end
end

% Plot the trap depth as a function of P and w0 with improved color distribution and contour lines
figure;
imagesc(log10(P_values), w0_values, trap_depth_matrix);
colorbar;
title('Trap Depth (\muK)');
xlabel('Log10(Power, W)');
ylabel('Beam Waist w_0 (\mum)');
set(gca, 'YDir', 'normal'); % Correct orientation

% Adjust the colormap and color limits
colormap('jet'); % Use a more colorful colormap
caxis([min(trap_depth_matrix(:)), max(trap_depth_matrix(:))]); % Set color axis to data range

% Add white contour lines at specific trap depth values
hold on;
contour(log10(P_values), w0_values, trap_depth_matrix, [100, 500, 1000], 'LineColor', 'w', 'LineWidth', 1.5);
hold off;