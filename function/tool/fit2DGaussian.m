function [fit_result, x, y, z, output] = fit2dGaussian(signal, options)
%FIT2DGAUSSIAN Fit a 2D gaussian on the 2D signal data. It wraps up the
% built-in fit function with properly-guessed initial parameters for the fit
% to converge.
% 
% [fit_result, x, y, z, output] = fit2dGaussian(signal)
% [fit_result, x, y, z, output] = fit2dGaussian(signal, Name, Value)
% 
%Available name-value pairs:
% "x_range": default is 1:size(signal, 1)
% "y_range": default is 1:size(signal, 2)
% "offset": default is "c", fit a 2D Gaussian surface with a constant
% offset; other options are "n" (no offset term), "linear" (2d linear term)
% "diagonal": logical, default is true. Whether to include x*y term in the
% fit
% "verbose": default true, whether to output diagonostic text

    arguments
        signal double
        options.xrange = 1: size(signal, 1)
        options.yrange = 1: size(signal, 2)
        options.offset = 'c'
        options.diagonal logical = true
        options.verbose logical = true
    end
    
    tic
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

    % Initial guess for the fit parameters
    upper = [5*diff,x_size,y_size,options.xrange(end),options.yrange(end), ...
        max_signal, max_signal/x_size, max_signal/y_size, inf];
    lower = [0,0.1*x_diff,0.1*y_diff,options.xrange(1),options.yrange(1), ...
        min_signal-0.1*diff, -max_signal/x_size, -max_signal/y_size, -inf];    
    start = [diff, x_size/10, y_size/10, max_x, max_y, 0, ...
        min_signal, 0, 0, 0];
    
    % Define 2D Gaussian fit type
    if options.diagonal
        switch options.offset
            case 'n'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0'});
                parameters = [1,2,3,4,5];
            case 'c'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))+c',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0','c'});
                parameters = [1,2,3,4,5,6];
            case 'linear'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2))+c1+c2*u+c3*v',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0','c1','c2','c3'});
                parameters = [1,2,3,4,5,6,7,8];
            otherwise
                error('Unknown fit offset!')
        end
    else
        switch options.offset
            case 'n'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2+2*d*(u-u0)*(v-v0)/(b1*b2))',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0','d'});
                parameters = [1,2,3,4,5,9];
            case 'c'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2)+2*d*(u-u0)*(v-v0)/(b1*b2))+c',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0','c','d'});
                parameters = [1,2,3,4,5,6,9];
            case 'linear'
                fit_type = fittype('a*exp(-0.5*((u-u0)^2/b1^2+(v-v0)^2/b2^2)+2*d*(u-u0)*(v-v0)/(b1*b2))+c1+c2*u+c3*v',...
                                'independent',{'u','v'},...
                                'coefficient',{'a','b1','b2','u0','v0','c1','c2','c3','d'});
                parameters = [1,2,3,4,5,6,7,8,9];
            otherwise
                error('Unknown fit offset!')
        end
    end

    foptions = fitoptions(fit_type);
    
    foptions.Upper = upper(parameters);
    foptions.Lower = lower(parameters);
    foptions.StartPoint = start(parameters);
    foptions.Display = "off";

    [fit_result, GOF, output] = fit([x, y], z, fit_type, foptions);

    if options.verbose
        disp(fit_result)
        disp(GOF)
        toc
    end
end