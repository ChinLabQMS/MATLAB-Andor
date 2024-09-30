function [fit_result, GOF, x, y, z] = fitGauss2D(signal, options)
%FIT2DGAUSSIAN Fit a 2D gaussian on the 2D signal data. It wraps up the
% built-in fit function with properly-guessed initial parameters for the fit
% to converge.
% 
% [fit_result, x, y, z, output] = fitGauss2D(signal)
% [fit_result, x, y, z, output] = fitGauss2D(signal, Name, Value)
% 
%Available name-value pairs:
% "x_range": default is 1:size(signal, 1)
% "y_range": default is 1:size(signal, 2)
% "offset": default is "c", fit a 2D Gaussian surface with a constant
% offset; other options are "n" (no offset term), "linear" (2d linear term)
% "cross_term": logical, default is false. Whether to include x*y term in the
% fit

    arguments
        signal (:, :, :) double
        options.x_range = 1: size(signal, 1)
        options.y_range = 1: size(signal, 2)
        options.offset = 'c'
        options.cross_term logical = false
    end

    if isscalar(options.x_range)
        options.x_range = 1:options.x_range;
    end
    if isscalar(options.y_range)
        options.y_range = 1:options.y_range;
    end
    
    % Define 2D Gaussian fit type
    if ~options.cross_term
        switch options.offset
            case 'n'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2))",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'}, ...
                                   "coefficient",{'a','s1','s2','x0','y0'});
                parameters = [1,2,3,4,5];
            case 'c'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2)) + b",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'}, ...
                                   "coefficient",{'a','s1','s2','x0','y0','b'});
                parameters = [1,2,3,4,5,6];
            case 'linear'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2)) + b + c1*x + c2*y",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'}, ...
                                   "coefficient",{'a','s1','s2','x0','y0','b','c1','c2'});
                parameters = [1,2,3,4,5,6,7,8];
            otherwise
                error('Unknown fit offset!')
        end
    else
        switch options.offset
            case 'n'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2)+2*d*(x-x0)*(y-y0)/(s1*s2))",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','d'});
                parameters = [1,2,3,4,5,9];
            case 'c'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2)+2*d*(x-x0)*(y-y0)/(s1*s2)) + b",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','b','d'});
                parameters = [1,2,3,4,5,6,9];
            case 'linear'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2)+2*d*(x-x0)*(y-y0)/(s1*s2)) + b + c1*x + c2*y",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','b','c1','c2','d'});
                parameters = [1,2,3,4,5,6,7,8,9];
            otherwise
                error('Unknown fit offset!')
        end
    end
    foptions = fitoptions(fit_type);

    signal = mean(signal, 3);
    [x_size, y_size] = size(signal);
    x_diff = options.x_range(2) - options.x_range(1);
    y_diff = options.y_range(2) - options.y_range(1);

    [y, x, z] = prepareSurfaceData(options.y_range, options.x_range, signal);
    [max_signal, max_index] = max(signal(:));
    min_signal = min(signal(:));
    diff = max_signal - min_signal;
    max_x = x(max_index);
    max_y = y(max_index);

    % Initial guess for the fit parameters
    upper = [5*diff, x_size, y_size, options.x_range(end), options.y_range(end), ...
             max_signal, max_signal/x_size, max_signal/y_size, Inf];
    lower = [0, 0.1*x_diff, 0.1*y_diff, options.x_range(1), options.y_range(1), ...
             min_signal-0.1*diff, -max_signal/x_size, -max_signal/y_size, -Inf];    
    start = [diff, x_size/10, y_size/10, max_x, max_y, ...
             min_signal, 0, 0, 0];
    
    foptions.Upper = upper(parameters);
    foptions.Lower = lower(parameters);
    foptions.StartPoint = start(parameters);
    foptions.Display = "off";

    [fit_result, GOF] = fit([x, y], z, fit_type, foptions);
end
