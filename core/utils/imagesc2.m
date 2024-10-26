function imagesc2(varargin, options)
    arguments (Repeating)
        varargin
    end
    arguments
        options.title (1, 1) string = ""
    end
    imagesc(varargin{:})
    axis image
    colorbar
    title(options.title)
end
