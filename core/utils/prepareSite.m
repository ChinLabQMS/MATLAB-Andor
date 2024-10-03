function lat_corr = prepareSite(format, options)
    arguments
        format (1, 1) string = "rect_lat"
        options.latx_range = -10:10
        options.laty_range = -10:10
        options.latr = 10
    end    
    switch format
        case 'rect_lat'
            [Y, X] = meshgrid(options.laty_range, options.latx_range);
            lat_corr = [X(:), Y(:)];
        case 'hex_lat'
            r = options.latr;
            [Y, X] = meshgrid(-r:r, -r:r);
            idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
            lat_corr = [X(idx), Y(idx)];   
    end
end
