function [f_res, output, x, y, z] = fitGauss2D(signal, x_range, y_range, options)
%FITGAUSS2D Fit a 2D gaussian on the 2D signal data. It wraps up the
% built-in fit function with properly-guessed initial parameters for the fit
% to converge.
% 
% [fit_result, output, x, y, z] = fitGauss2D(signal)
% [fit_result, output, x, y, z] = fitGauss2D(signal, x_range, y_range)
% [fit_result, output, x, y, z] = fitGauss2D(_, Name, Value)
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
        x_range {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
        y_range {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
        options.sub_sample = 1
        options.offset = 'c'
        options.cross_term = false
        options.plot_diagnostic = false
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
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2+2*d*(x-x0)*(y-y0)/(s1*s2)))",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','d'});
                parameters = [1,2,3,4,5,9];
            case 'c'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2+2*d*(x-x0)*(y-y0)/(s1*s2))) + b",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','b','d'});
                parameters = [1,2,3,4,5,6,9];
            case 'linear'
                fit_type = fittype("a*exp(-0.5*((x-x0)^2/s1^2+(y-y0)^2/s2^2+2*d*(x-x0)*(y-y0)/(s1*s2))) + b + c1*x + c2*y",...
                                   "dependent", "z", ...
                                   "independent",{'x','y'},...
                                   "coefficient",{'a','s1','s2','x0','y0','b','c1','c2','d'});
                parameters = [1,2,3,4,5,6,7,8,9];
            otherwise
                error('Unknown fit offset!')
        end
    end
    foptions = fitoptions(fit_type);
    
    % Sub-sample the image (to make computation faster)
    signal = mean(signal, 3);
    [x_size, y_size] = size(signal);
    signal = signal(1:options.sub_sample:x_size, 1:options.sub_sample:y_size);

    x_range = x_range(1:options.sub_sample:x_size);
    y_range = y_range(1:options.sub_sample:y_size);
    x_diff = x_range(2) - x_range(1);
    y_diff = y_range(2) - y_range(1);

    [y, x, z] = prepareSurfaceData(y_range, x_range, signal);
    [max_signal, max_index] = max(signal(:));
    min_signal = min(signal(:));
    diff = max_signal - min_signal;
    max_x = x(max_index);
    max_y = y(max_index);

    % Initial guess for the fit parameters: a, s1, s2, x0, y0, b, c1, c2, d
    upper = [5*diff,    x_size,         y_size,         x_range(end),   y_range(end),   max_signal+0.1*diff,    diff/x_size,    max_signal/y_size,  Inf];
    lower = [0,         0.1*x_diff,     0.1*y_diff,     x_range(1),     y_range(1),     min_signal-0.1*diff,    -diff/x_size,   -max_signal/y_size, -Inf];
    start = [diff,      x_size/10,      y_size/10,      max_x,          max_y,          min_signal,             0,              0,                  0];
    
    foptions.Upper = upper(parameters);
    foptions.Lower = lower(parameters);
    foptions.StartPoint = start(parameters);
    foptions.Display = "off";

    [f_res, output] = fit([x, y], z, fit_type, foptions);
    if options.cross_term
        mat = [1/(f_res.s1)^2, f_res.d/(f_res.s1 * f_res.s2); 
               f_res.d/(f_res.s1 * f_res.s2), 1/(f_res.s2)^2];
        [V, D] = eig(mat, 'vector');
        [D, ind] = sort(D, 'descend');
        V = V(:, ind);
        output.eigen_angles = acosd(V(1, :));
        output.eigen_vectors = V;
        output.eigen_values = D';
        output.eigen_widths = 1./sqrt(D');
    end

    if options.plot_diagnostic
        figure
        subplot(1, 2, 1)
        plot(f_res, [x, y], z)
        xlabel('X')
        ylabel('Y')
        subplot(1, 2, 2)
        imagesc2(y_range, x_range, signal)
        viscircles([f_res.y0, f_res.x0], mean([f_res.s1, f_res.s2])/10, 'LineWidth', 2);
        if options.cross_term
            v1 = output.eigen_widths(1) * output.eigen_vectors(:, 1);
            v2 = output.eigen_widths(2) * output.eigen_vectors(:, 2);
            hold on
            quiver(f_res.y0, f_res.x0, v1(2), v1(1), ...
                'LineWidth', 2, 'Color', 'r', 'MaxHeadSize', 10, 'DisplayName', sprintf("major width: %.3g", output.eigen_widths(1)))
            quiver(f_res.y0, f_res.x0, v2(2), v2(1), ...
                'LineWidth', 2, 'Color', 'm', 'MaxHeadSize', 10, 'DisplayName', sprintf("minor width: %.3g", output.eigen_widths(2)))
            hold off
            legend()
        end
    end
end
