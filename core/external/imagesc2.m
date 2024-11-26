function varargout = imagesc2(varargin, options)
    arguments (Repeating)
        varargin
    end
    arguments
        options.title (1, 1) string = ""
    end
    h = imagesc(varargin{:});
    axis image
    colorbar
    title(options.title, 'Interpreter', 'none')
    if nargout == 1
        varargout{1} = h;
    end
end
