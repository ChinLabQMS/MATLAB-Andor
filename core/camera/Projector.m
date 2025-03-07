classdef (Abstract) Projector < BaseProcessor
    % PROJECTOR Base class for controlling window content to display
    % patterns on a projector, wrapped around C++ mex function
    % The compiled C++ mex function is assumed to be on MATLAB search path

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
        StaticPattern
        StaticPatternRGB
        StaticPatternReal
        StaticPatternRealRGB
        StaticPatternPath
        PatternCanvas
        PatternCanvasRGB
        RealCanvas
        RealCanvasRGB
        NumLoadedPatternsInMemory
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

        % Open pattern window
        function open(obj, options)
            arguments
                obj
                options.verbose = true
            end
            if ~obj.IsWindowCreated
                obj.MexHandle("open", obj.PixelArrangement, false)
                if options.verbose
                    obj.info('Window created.')
                end
            end
        end
        
        % Close pattern window
        function close(obj, options)
            arguments
                obj 
                options.verbose = true
            end
            if obj.IsWindowCreated
                obj.MexHandle("close", false)
                if options.verbose
                    obj.info('Window closed.')
                end
            end
        end

        % Main function to interface with the app
        function project(obj, live, options)
            arguments
                obj
                live = []  % Live data from acquisitor
                options.red = 0
                options.green = 0
                options.blue = 0
            end
            switch options.mode
                case "SolidColor"
                    obj.displayColor(options.red, options.green, options.blue)
                case "DynamicPreloaded"
                    
                case "Dynamic"
                    obj.warn2("Not implemented yet!")
            end
        end
        
        % Project a static pattern (external BMP) on projector
        function setStaticPatternPath(obj, path)
            path = string(path);
            obj.checkFilePath(path, 'StaticPatternPath');
            obj.MexHandle("setStaticPatternPath", path, false)
            obj.info("Static pattern loaded from '%s'.", path)
        end
            
        % Display a solid color
        function displayColor(obj, r, g, b)
            obj.MexHandle("displayColor", [r, g, b], false)
        end

        % Set the index of the display to position window
        function setDisplayIndex(obj, index, options)
            arguments
                obj
                index = -1
                options.verbose = true
            end
            obj.MexHandle("setDisplayIndex", index, false)
            if options.verbose
                obj.info('Display is set to index %d.', index)
            end
        end
        
        function selectAndProject(obj, options)
            arguments
                obj
                options.verbose = true
            end
            obj.MexHandle("selectAndProject", false)
            if options.verbose
                obj.info('Static pattern path is set to %s', obj.StaticPatternPath)
            end
        end

        function selectAndLoadPatternMemory(obj)
            obj.MexHandle("selectAndLoadPatternMemory", false)
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

        function val = get.StaticPattern(obj)
            val = obj.MexHandle("getStaticPattern");
        end

        function val = get.StaticPatternRGB(obj)
            val = obj.MexHandle("getStaticPatternRGB");
        end

        function val = get.StaticPatternReal(obj)
            val = obj.MexHandle("getStaticPatternReal");
        end

        function val = get.StaticPatternRealRGB(obj)
            val = obj.MexHandle("getStaticPatternRealRGB");
        end
        
        function val = get.StaticPatternPath(obj)
            val = string(obj.MexHandle("getStaticPatternPath"));
        end

        function val = get.PatternCanvas(obj)
            val = obj.MexHandle("getPatternCanvas");
        end

        function val = get.PatternCanvasRGB(obj)
            val = obj.MexHandle("getPatternCanvasRGB");
        end

        function val = get.RealCanvas(obj)
            val = obj.MexHandle("getRealCanvas");
        end

        function val = get.RealCanvasRGB(obj)
            val = obj.MexHandle("getRealPatternCanvasRGB");
        end

        function val = get.NumLoadedPatternsInMemory(obj)
            val = obj.MexHandle("getNumLoadedPatterns");
        end
    end

    methods (Access = protected)
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
            r = uint8(bitshift(bitand(pattern, 0xFF0000), -16));
            g = uint8(bitshift(bitand(pattern, 0x00FF00), -8));
            b = uint8(bitand(pattern, 0x0000FF));
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
