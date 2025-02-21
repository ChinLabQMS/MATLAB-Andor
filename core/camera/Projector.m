classdef (Abstract) Projector < BaseProcessor
    % PROJECTOR Base class for controlling window content to display
    % patterns on a projector, wrapped around C++ mex function

    properties (SetAccess = immutable)
        ID
        MexHandle
    end

    properties (Abstract, SetAccess = immutable)
        MexFunctionName
        DefaultStaticPatternPath
        PixelArrangement
    end

    properties (Dependent)
        IsWindowCreated
        IsWindowMinimized
        WindowHeight
        WindowWidth
        StaticPatternPath
        DynamicPattern
    end

    properties (SetAccess = protected)
        RealNumRows             % Number of rows in real space
        RealNumCols             % Number of cols in real space
        PixelIndex              % Full range of pixel index in projector space
        RealPixelIndex          % Active pixel index in real space
        RealBackgroundIndex     % Background pixel index in real space
        StaticPattern           % Static pattern in uint32 format
        StaticPatternRGB        % Static pattern (h x w x 3) uint8 format
        StaticPatternReal
        StaticPatternRealRGB
    end

    methods
        function obj = Projector(id)
            arguments
                id = "Test"
            end
            obj@BaseProcessor()
            clear(obj.MexFunctionName)
            obj.MexHandle = str2func(obj.MexFunctionName);
            obj.MexHandle("lock")
            obj.ID = id;
            obj.setStaticPatternPath(obj.DefaultStaticPatternPath)
        end

        % Main function to interface with the app
        function project(obj, live, options)
            arguments
                obj
                live = []  % Live data from acquisitor
                options.mode = "Static"
                options.static_pattern_path = obj.DefaultStaticPatternPath
            end
            switch options.mode
                case "Static"
                    obj.setStaticPatternPath(options.static_pattern_path)
                case "Dynamic"
                    obj.warn2("Not implemented yet!")
            end
        end
        
        function setStaticPatternPath(obj, path)
            path = string(path);
            obj.checkFilePath(path, 'StaticPatternPath');
            obj.MexHandle("setStaticPatternPath", path, false)
            obj.updateStaticPatternProp()
            obj.info("Static pattern loaded from '%s'.", path)
        end

        function setDynamicPattern(obj, pattern)
            % Add 8-bit of 1 in the beginning for transparency (opaque)
            pattern = bitor(uint32(pattern), 0b11111111000000000000000000000000);
            for i = 1: size(pattern, 3)
                obj.MexHandle("setDynamicPattern", pattern(:, :, i), false)
            end
        end

        function setDynamicPatternRGB(obj, rgb)
            if size(rgb, 3) ~= 3
                obj.error('Pattern should be M x N x 3 array!')
            end
            pattern = permute(RGB2Pattern(rgb), [2, 1, 3]);
            obj.MexHandle("setDynamicPattern", pattern, false)
        end

        function displayColor(obj, r, g, b)
            obj.MexHandle("displayColor", [r, g, b])
        end

        function open(obj, verbose)
            arguments
                obj
                verbose = false
            end
            if ~obj.IsWindowCreated
                obj.MexHandle("open", verbose)
                obj.updateStaticPatternProp()
                obj.info('Window created.')
            end
        end

        function close(obj, verbose)
            arguments
                obj 
                verbose = false
            end
            if obj.IsWindowCreated
                obj.MexHandle("close", verbose)
                obj.info('Window closed.')
            end
        end

        function setDisplayIndex(obj, index, verbose)
            arguments
                obj
                index = -1
                verbose = false
            end
            obj.MexHandle("setDisplayIndex", index, verbose)
        end

        function selectPatternFromFile(obj)
            [file, location] = uigetfile('*.bmp', 'Select a BMP pattern to display');
            if file ~= 0
                obj.setStaticPatternPath(fullfile(location, file));
            end
        end

        function plot(obj, ax1, ax2)
            arguments
                obj
                ax1 = []
                ax2 = []
            end
            if isempty(ax1) && isempty(ax2)
                figure
                ax1 = subplot(1, 2, 1);
                ax2 = subplot(1, 2, 2);
            end
            imagesc(ax1, obj.StaticPatternRGB)
            title(ax1, 'Static Pattern')
            axis(ax1, "image")
            imagesc(ax2, obj.StaticPatternRealRGB)
            title(ax2, 'Static Pattern (real space)')
            axis(ax2, "image")
        end

        function delete(obj)
            obj.close()
            obj.MexHandle("unlock")
            clear(obj.MexFunctionName)
        end

        function checkWindowState(obj)
            if ~obj.IsWindowCreated
                obj.open()
            elseif obj.IsWindowMinimized
                obj.error('Window is minimized!')
            end
        end

        function val = struct(obj)
            val = struct@BaseProcessor(obj, obj.VisibleProp);
        end

        function val = get.IsWindowCreated(obj)
            val = obj.MexHandle("isWindowCreated");
        end

        function val = get.IsWindowMinimized(obj)
            val = obj.MexHandle("isWindowMinimized");
        end

        function val = get.WindowHeight(obj)
            val = double(obj.MexHandle("getWindowHeight"));
        end

        function val = get.WindowWidth(obj)
            val = double(obj.MexHandle("getWindowWidth"));
        end

        function val = get.StaticPatternPath(obj)
            val = string(obj.MexHandle("getStaticPatternPath"));
        end

        function val = get.DynamicPattern(obj)
            val = uint32(obj.MexHandle("getDynamicPattern"));
        end
    end

    methods (Access = protected)
        function updateStaticPatternProp(obj)
            obj.updateRealSpaceMap()
            obj.StaticPattern = permute(uint32(obj.MexHandle("getStaticPattern")), [2, 1, 3]);
            obj.StaticPatternRGB = Pattern2RGB(obj.StaticPattern);
            obj.StaticPatternReal = zeros(obj.RealNumRows, obj.RealNumCols, 'uint32');
            obj.StaticPatternReal(obj.RealPixelIndex) = obj.StaticPattern(obj.PixelIndex);
            obj.StaticPatternReal(obj.RealBackgroundIndex) = 0b111111110000000000000000;
            obj.StaticPatternRealRGB = Pattern2RGB(obj.StaticPatternReal);
        end

        % Update the real-space pixel index and projector space index
        % correspondence
        function updateRealSpaceMap(obj)
            % Projector space index
            nrows = obj.WindowHeight;
            ncols = obj.WindowWidth;
            [Y, X] = meshgrid(1: ncols, 1: nrows);
            obj.PixelIndex = sub2ind([nrows, ncols], X(:), Y(:));
            % Real space index
            switch obj.PixelArrangement
                case "Square"
                    obj.RealNumRows = nrows;
                    obj.RealNumCols = ncols;
                    obj.RealPixelIndex = obj.PixelIndex;
                    obj.RealBackgroundIndex = [];
                case "Diamond"
                    obj.RealNumRows = max(0, ceil((nrows - 1) / 2) + ncols);
                    obj.RealNumCols = max(0, ncols + floor((nrows - 1) / 2));
                    RealX = ceil((nrows - X) / 2) + Y;
                    RealY = floor((nrows - X) / 2) + ncols - Y + 1;
                    obj.RealPixelIndex = sub2ind([obj.RealNumRows, obj.RealNumCols], RealX(:), RealY(:));
                    real_idx = true(obj.RealNumCols * obj.RealNumRows, 1);
                    real_idx(obj.RealPixelIndex) = false;
                    real_idx_full = 1: obj.RealNumCols * obj.RealNumRows;
                    obj.RealBackgroundIndex = real_idx_full(real_idx);
            end
        end

        function label = getStatusLabel(obj)
            label = getStatusLabel@BaseProcessor(obj) + sprintf("(WindowOpen: %d)", obj.IsWindowCreated);
        end
    end

    methods (Static)
        function info = getDisplayInformation(format)
            arguments
                format = "table"
            end
            info = PatternWindowMex("getDisplayModes");
            switch format
                case "struct"
                case "table"
                    info = struct2table(info);
                case "string"
                    num_display = length(info);
                    strarr = strings(num_display, 1);
                    for i = 1: length(info)
                        strarr(i) = sprintf("Display#%d: %d x %d, %.1f Hz", ...
                            i, info(i).Width, info(i).Height, info(i).RefreshRate);
                    end
                    info = strarr;
                otherwise
                    error('Unknown format for display information!')
            end
        end
    end

end

function rgb = Pattern2RGB(pattern)
    r = uint8(bitshift(bitand(pattern, 0b111111110000000000000000), -16));
    g = uint8(bitshift(bitand(pattern, 0b000000001111111100000000), -8));
    b = uint8(bitand(pattern, 0b000000000000000011111111));
    rgb = cat(3, r, g, b);
end

function pattern = RGB2Pattern(rgb)
    r = bitshift(uint32(rgb(:, :, 1)), 16);
    g = bitshift(uint32(rgb(:, :, 2)), 8);
    b = uint32(rgb(:, :, 3));
    pattern = r + g + b + 0b11111111000000000000000000000000;
end
