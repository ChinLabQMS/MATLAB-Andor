function [f_res, output] = fitGauss1D(signal, x_range, options)
%FITGAUSS1D Fit a 1D gaussian on the 1D signal data. It wraps up the
% built-in fit function with properly-guessed initial parameters for the fit
% to converge.

    arguments
        signal (1, :) double
        x_range {mustBeValidRange(signal, 2, x_range)} = 1: size(signal, 2)
        options.sub_sample = 1
        options.offset = 'c'
    end
    
    % Define 1D Gaussian fit type
    switch options.offset
        case 'n'
            fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2))",...
                               "dependent", "z", ...
                               "independent",{'x'}, ...
                               "coefficient",{'a','s1','x0'});
            parameters = [1,2,3];
        case 'c'
            fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2)) + b",...
                               "dependent", "z", ...
                               "independent",{'x'}, ...
                               "coefficient",{'a','s1','x0','b'});
            parameters = [1,2,3,4];
        case 'linear'
            fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2)) + b + c1*x",...
                               "dependent", "z", ...
                               "independent",{'x'}, ...
                               "coefficient",{'a','s1','x0','b','c1'});
            parameters = [1,2,3,4,5];
        otherwise
            error('Unknown fit offset!')
    end   
    foptions = fitoptions(fit_type);
    
    % Sub-sample the image (to make computation faster)
    options.sub_sample = max(options.sub_sample, 1);
    x_size = size(signal, 2);
    signal = signal(1:options.sub_sample:x_size);
    x_range = x_range(1:options.sub_sample:x_size);

    x_diff = x_range(2) - x_range(1);

    [max_signal, max_index] = max(signal(:));
    min_signal = min(signal(:));
    diff = max_signal - min_signal;
    max_x = x_range(max_index);

    % Initial guess for the fit parameters
    upper = [5*diff,    x_size,         x_range(end),   max_signal,             diff/x_size];
    lower = [0,         0.1*x_diff,     x_range(1),     min_signal-0.1*diff,    -diff/x_size];    
    start = [diff,      x_size/10,      max_x,          min_signal,             0];
    
    foptions.Upper = upper(parameters);
    foptions.Lower = lower(parameters);
    foptions.StartPoint = start(parameters);
    foptions.Display = "off";

    [f_res, output] = fit(x_range', signal', fit_type, foptions);
end
