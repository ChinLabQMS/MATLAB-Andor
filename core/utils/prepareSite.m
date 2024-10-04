function lat_corr = prepareSite(format, options)
    arguments
        format (1, 1) string = "hex"
        options.latx_range = -10:10
        options.laty_range = -10:10
        options.latr = 10
    end    
    switch format
        case 'rect'
            [Y, X] = meshgrid(options.laty_range, options.latx_range);
            lat_corr = [X(:), Y(:)];
        case 'hex'
            r = options.latr;
            [Y, X] = meshgrid(-r:r, -r:r);
            idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
            lat_corr = [X(idx), Y(idx)];
        otherwise
            error("Not implemented")
    end
end
