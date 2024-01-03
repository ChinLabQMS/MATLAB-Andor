function [fit_result, GOF, x, y, z, output] = fit2dGaussian(signal, options)
%FIT2DGAUSSIAN Fit a 2D gaussian on the 2D signal data. It uses the built-in
%function from MATLAB but with properly-set parameters for the fit to
%converge.
% 
% [fit_result, GOF, x, y, z, output] = fit2dGaussian(signal, 'x_range', x_range, 'y_range', y_range, 'offset', 'c')

    arguments
        signal double
        options.xrange = 1: size(signal, 1)
        options.yrange = 1: size(signal, 2)
        options.offset = 'c'
    end
    if length(options.xrange) == 1
        options.xrange = 1:options.xrange;
    end
    if length(options.yrange) == 1
        options.yrange = 1:options.yrange;
    end
    
    [x_size, y_size] = size(signal);
    x_diff = options.xrange(2) - options.xrange(1);
    y_diff = options.yrange(2) - options.yrange(1);

    [y, x, z] = prepareSurfaceData(options.yrange,options.xrange,signal);
    [max_signal, max_index] = max(signal(:));
    min_signal = min(signal(:));
    diff = max_signal - min_signal;
    max_x = x(max_index);
    max_y = y(max_index);
    
    % Define 2D Gaussian fit type
    switch options.offset
        case 'n'
            num_pars = 5;
            ftype = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))',...
                            'independent',{'u','v'},...
                            'coefficient',{'a','b1','b2','u0','v0'});
        case 'c'
            num_pars = 6;
            ftype = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))+c',...
                            'independent',{'u','v'},...
                            'coefficient',{'a','b1','b2','u0','v0','c'});        
        case 'linear'
            num_pars = 8;
            ftype = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))+c1+c2*u+c3*v',...
                            'independent',{'u','v'},...
                            'coefficient',{'a','b1','b2','u0','v0','c1','c2','c3'});
        otherwise
            error('Unknown fit offset!')
    end

    foptions = fitoptions(ftype);
    upper_limit = [5*diff, x_size, y_size, ...
            options.xrange(end), options.yrange(end), ...
            max_signal, max_signal/x_size, max_signal/y_size];
    lower_limit = [0, 0.1*x_diff, 0.1*y_diff, ...
            options.xrange(1), options.yrange(1), ...
            min_signal - 0.1*diff, -max_signal/x_size, -max_signal/y_size];
    start_point = [diff, x_size/10, y_size/10, ...
            max_x, max_y, ...
            min_signal, 0, 0];

    foptions.Upper = upper_limit(1:num_pars);
    foptions.Lower = lower_limit(1:num_pars);
    foptions.StartPoint = start_point(1:num_pars);

    foptions.Display = "off";

    [fit_result, GOF, output] = fit([x, y], z, ftype, foptions);
end