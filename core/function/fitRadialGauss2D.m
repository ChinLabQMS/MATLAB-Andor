function [fit_result, GOF, x, y, z] = fitRadialGauss2D(signal, options)
%FITRADIALGAUSS2D Fit a 2D Gaussian on the radial distance from the center.
% 
% [fit_result, x, y, z, GOF] = fitRadialGauss2D(signal)
% [fit_result, x, y, z, GOF] = fitRadialGauss2D(signal, Name, Value)
% 
% Available name-value pairs:
% "x_range": default is 1:size(signal, 1)
% "y_range": default is 1:size(signal, 2)
% "offset": default is "c", fit a 2D Gaussian surface with a constant offset;
% "cross_term": logical, default is false. This term is not used in this version.
    
    arguments
        signal (:, :, :) double
        options.x_range = 1: size(signal, 1)
        options.y_range = 1: size(signal, 2)
        options.offset = 'c'
    end

    if isscalar(options.x_range)
        options.x_range = 1:options.x_range;
    end
    if isscalar(options.y_range)
        options.y_range = 1:options.y_range;
    end
    
    % Define radial 2D Gaussian fit type
    switch options.offset
        case 'n'
            fit_type = fittype("a*exp(-0.5*((sqrt(x^2 + y^2)-r0)^2/s^2))", ...
                               "dependent", "z", ...
                               "independent", {'x', 'y'}, ...
                               "coefficient", {'a', 's', 'r0'});
            parameters = [1, 2, 3];
        case 'c'
            fit_type = fittype("a*exp(-0.5*((sqrt(x^2 + y^2)-r0)^2/s^2)) + b", ...
                               "dependent", "z", ...
                               "independent", {'x', 'y'}, ...
                               "coefficient", {'a', 's', 'r0', 'b'});
            parameters = [1, 2, 3, 4];
        otherwise
            error('Unknown fit offset!')
    end
    
    foptions = fitoptions(fit_type);
    
    % Average over 3rd dimension if 3D
    signal = mean(signal, 3);
    [x_size, y_size] = size(signal);

    % Prepare data for fitting
    [y, x, z] = prepareSurfaceData(options.y_range, options.x_range, signal);
    [max_signal, max_index] = max(signal(:));
    min_signal = min(signal(:));
    diff = max_signal - min_signal;
    max_x = x(max_index);
    max_y = y(max_index);

    % Initial guesses for parameters
    r0_guess = sqrt(max_x^2 + max_y^2);
    upper = [5*diff, max([x_size, y_size]), Inf, max_signal];
    lower = [0, 0.1, 0, min_signal-0.1*diff];    
    start = [diff, max([x_size, y_size])/10, r0_guess, min_signal];
    
    foptions.Upper = upper(parameters);
    foptions.Lower = lower(parameters);
    foptions.StartPoint = start(parameters);
    foptions.Display = 'off';

    % Perform the fit
    [fit_result, GOF] = fit([x, y], z, fit_type, foptions);
end
