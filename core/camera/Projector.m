classdef (Abstract) Projector < BaseProcessor
    % PROJECTOR Base class for controlling window content to display
    % patterns on a projector, wrapped around C++ mex function
    % The compiled C++ mex function is assumed to be on MATLAB search path
    
    properties (Constant)
        Background_Color = 0b111111110000000000000000
    end

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
        NumDynamicPatternInMemory
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
        PatternMemory
        PatternCanvas
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
                options.red = 0
                options.green = 0
                options.blue = 0
                options.range = []
            end
            switch options.mode
                case "Static"
                    obj.setStaticPatternPath(options.static_pattern_path)
                case "SolidColor"
                    obj.displayColor(options.red, options.green, options.blue)
                case "DynamicPreloaded"
                    if isempty(options.range)
                        obj.setDynamicPattern(obj.PatternMemory)
                    else
                        obj.setDynamicPattern(obj.PatternMemory(:,:,options.range))
                    end
                case "Dynamic"
                    obj.warn2("Not implemented yet!")
            end
        end
        
        % Project a static pattern (external BMP) on projector
        function setStaticPatternPath(obj, path)
            path = string(path);
            obj.checkFilePath(path, 'StaticPatternPath');
            obj.MexHandle("setStaticPatternPath", path, false)
            if obj.IsWindowCreated
                obj.updateStaticPatternProp()
            end
            obj.info("Static pattern loaded from '%s'.", path)
        end
        
        % Project a series of uint32 pattern(s) on projector
        function setDynamicPattern(obj, pattern)
            if isempty(pattern)
                obj.warn2('Dynamic pattern to set is empty!')
                return
            end
            % Add 8-bit of 1 in the beginning for transparency (opaque)
            pattern = permute(bitor(uint32(pattern), 0b11111111000000000000000000000000), [2, 1, 3]);
            for i = 1: size(pattern, 3)
                obj.MexHandle("setDynamicPattern", pattern(:, :, i), false)
            end
        end

        % Open pattern window
        function open(obj, verbose)
            arguments
                obj
                verbose = false
            end
            if ~obj.IsWindowCreated
                obj.MexHandle("open", verbose)
                obj.updateRealSpaceMap()
                obj.updateStaticPatternProp()
                obj.info('Window created.')
            end
        end
        
        % Close pattern window
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
    
        % Display a solid color
        function displayColor(obj, r, g, b)
            obj.MexHandle("displayColor", [r, g, b])
        end

        % Set the index of the display to position window
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
            if ~isequal(file, 0)
                obj.setStaticPatternPath(fullfile(location, file));
            end
        end

        function loadPatternMemoryFromFile(obj)
            [file, location] = uigetfile('*.bmp', ...
                'Select BMP pattern(s) to load into memory', ...
                'MultiSelect', 'on');
            if ~isequal(file, 0)
                if iscell(file)
                    for i = 1: length(file)
                        pattern = obj.RGB2Pattern(imread(fullfile(location, file{i})));
                    end
                else
                    pattern = obj.RGB2Pattern(imread(fullfile(location, file)));
                end                
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

        function checkWindowState(obj)
            if ~obj.IsWindowCreated
                obj.open()
            elseif obj.IsWindowMinimized
                obj.error('Window is minimized!')
            end
        end

        % Convert the projector space pattern to real space pattern
        function val = convertPattern2Real(obj, pattern)
            val = zeros(obj.RealNumRows, obj.RealNumCols, 'uint32');
            val(obj.RealPixelIndex) = pattern(obj.PixelIndex);
            val(obj.RealBackgroundIndex) = obj.Background_Color;
        end

        function val = convertReal2Pattern(obj, pattern)
        end

        function delete(obj)
            obj.close()
            obj.MexHandle("unlock")
            clear(obj.MexFunctionName)
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

        function val = get.NumDynamicPatternInMemory(obj)
            if isempty(obj.PatternMemory)
                val = 0;
            else
                val = size(obj.PatternMemory, 3);
            end
        end
    end

    methods (Access = protected)
        function updateStaticPatternProp(obj)
            obj.StaticPattern = permute(uint32(obj.MexHandle("getStaticPattern")), [2, 1, 3]);
            obj.StaticPatternRGB = obj.Pattern2RGB(obj.StaticPattern);
            obj.StaticPatternReal(obj.RealPixelIndex) = obj.StaticPattern(obj.PixelIndex);
            obj.StaticPatternReal(obj.RealBackgroundIndex) = obj.Background_Color;
            obj.StaticPatternRealRGB = obj.Pattern2RGB(obj.StaticPatternReal);
        end

        % Update the real-space pixel index and projector space index
        % mapping
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
            obj.StaticPatternReal = zeros(obj.RealNumRows, obj.RealNumCols, 'uint32');
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
    end
    
end
