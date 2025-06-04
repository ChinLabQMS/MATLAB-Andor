classdef Projector < BaseRunner
    % PROJECTOR Base class for controlling window content to display
    % patterns on a projector, wrapped around C++ mex function
    % The compiled C++ mex function is assumed to be on MATLAB search path

    properties (SetAccess = immutable)
        ID
        MexHandle
    end

    properties (Dependent)
        IsWindowCreated
        IsWindowMinimized
        WindowHeight
        WindowWidth
        OperationMode
        StaticPattern
        StaticPatternRGB
        StaticPatternReal
        StaticPatternRealRGB
        StaticPatternPath
        NumLoadedPatternsInMemory
    end

    methods
        function obj = Projector(id, config)
            arguments
                id = "Test"
                config = DMDConfig()
            end
            obj@BaseRunner(config)
            clear(obj.Config.MexFunctionName)
            obj.MexHandle = str2func(obj.Config.MexFunctionName);
            obj.ID = id;
        end

        % Open pattern window with default static pattern
        function open(obj, options)
            arguments
                obj
                options.verbose = true
            end
            obj.MexHandle("lock")
            if ~obj.IsWindowCreated
                obj.MexHandle("open", obj.Config.PixelArrangement, false)
                if options.verbose
                    obj.info('Window is opened.')
                end
                obj.setStaticPatternPath(obj.Config.DefaultStaticPatternPath)
                obj.preloadPatternMemory()
            end
        end
        
        % Close pattern window (which will reset the memory)
        function close(obj, options)
            arguments
                obj 
                options.verbose = true
            end
            if obj.IsWindowCreated
                obj.MexHandle("close", false)
                if options.verbose
                    obj.info('Window is closed.')
                end
            end
            obj.MexHandle("unlock")
            clear(obj.Config.MexFunctionName)
        end

        % Main function to interface with the app
        function project(obj, live, options)
            arguments
                obj
                live = []  % Live data from Acquisitor
                options.mode = "SolidColor"
                options.red = 0
                options.green = 0
                options.blue = 0
                options.pattern_index = 0
                options.pattern_delay = 0
                options.live_camera = "Andor19330"
                options.live_label = "Image"
                options.black_tweezer_radius = 6
            end
            switch options.mode
                case "SolidColor"
                    obj.displayColor(options.red, options.green, options.blue)
                case "DynamicPreloaded"
                    success = obj.displayPatternMemory(options.pattern_index, "pattern_delay",options.pattern_delay);
                    if ~success && ~isempty(live)
                        % Flag the bad projection
                        live.BadFrameDetected = true;
                    end
                case "DynamicBlackTweezers"
                    if isfield(live.Temporary, options.live_camera) && ...
                       isfield(live.Temporary.(options.live_camera), options.live_label) && ...
                       isfield(live.Temporary.(options.live_camera).(options.live_label), "SiteStat")
                        stat = live.Temporary.(options.live_camera).(options.live_label).SiteStat;
                        sites = stat.SiteInfo.Sites(stat.LatOccup, :);
                        coord = live.LatCalib.DMD.convert2Real(sites);
                        obj.MexHandle("generateBlackTweezerPattern", coord, ...
                            options.black_tweezer_radius, [0,0], 1, 0, true) % [-0.717,-0.776]
                        obj.MexHandle("displayDynamicMemoryAll", 0, false, true)
                        obj.MexHandle("clearDynamicMemory")
                    else
                        live.BadFrameDetected = true;
                    end                    
            end
        end

        function projectBlackTweezerPattern(obj, ...
                coord, radius, shift, ...
                num_buffers, num_moving_frames, delay)
            obj.MexHandle("generateBlackTweezerPattern", coord, radius, shift, num_buffers, num_moving_frames, true)
            obj.MexHandle("displayDynamicMemoryAll", delay, false, true)
            obj.MexHandle("clearDynamicMemory")
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
        
        % Preload the pattern memory with the BMPs from default paths
        function preloadPatternMemory(obj)
            for path = obj.Config.PreloadPatternPath
                obj.MexHandle("loadPatternMemoryFromPath", path, false)
                obj.info("Pattern loaded from path to the memory: %s", path)
            end
        end
        
        % Display a pattern from loaded memory
        function varargout = displayPatternMemory(obj, index, options)
            arguments
                obj
                index
                options.pattern_delay = 0
            end
            output = obj.MexHandle("displayPatternMemory", index, options.pattern_delay, false);
            if nargout == 1
                varargout{1} = output;
            end
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

        function clearPatternMemory(obj)
            obj.MexHandle("clearPatternMemory")
        end

        function val = getPatternMemoryRGB(obj, index)
            val = obj.MexHandle("getPatternMemoryRGB", index);
        end

        function val = getPatternMemoryRealRGB(obj, index)
            val = obj.MexHandle("getPatternMemoryRealRGB", index);
        end

        function val = getDynamicMemoryRGB(obj, index)
            val = obj.MexHandle("getDynamicMemoryRGB", index);
        end

        function val = getDynamicMemoryRealRGB(obj, index)
            val = obj.MexHandle("getDynamicMemoryRealRGB", index);
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

        function plot2(obj, index, ax1, ax2)
            arguments
                obj
                index = 0
                ax1 = []
                ax2 = []
            end
            if isempty(index)
                return
            end
            if isempty(ax1) && isempty(ax2)
                figure
                ax1 = subplot(1, 2, 1);
                ax2 = subplot(1, 2, 2);
            end
            pattern1 = obj.getPatternMemoryRGB(index);
            pattern2 = obj.getPatternMemoryRealRGB(index);
            imagesc(ax1, pattern1)
            title(ax1, sprintf('Dynamic pattern: %d', index))
            axis(ax1, "image")
            imagesc(ax2, pattern2)
            title(ax2, sprintf('Dynamic pattern (real space): %d', index))
            axis(ax2, "image")
        end

        function plot3(obj, index, ax1, ax2)
            arguments
                obj
                index = 0
                ax1 = []
                ax2 = []
            end
            if isempty(index)
                return
            end
            if isempty(ax1) && isempty(ax2)
                figure
                ax1 = subplot(1, 2, 1);
                ax2 = subplot(1, 2, 2);
            end
            pattern1 = obj.getDynamicMemoryRGB(index);
            pattern2 = obj.getDynamicMemoryRealRGB(index);
            imagesc(ax1, pattern1)
            title(ax1, sprintf('Dynamic pattern: %d', index))
            axis(ax1, "image")
            imagesc(ax2, pattern2)
            title(ax2, sprintf('Dynamic pattern (real space): %d', index))
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

        function val = get.OperationMode(obj)
            val = string(obj.MexHandle("getOperationMode"));
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

        function val = get.NumLoadedPatternsInMemory(obj)
            val = obj.MexHandle("getNumLoadedPatterns");
        end
    end

    methods (Access = protected)
        function label = getStatusLabel(obj)
            label = getStatusLabel@BaseRunner(obj) + sprintf("(%s)", obj.ID);
        end
    end

    methods (Static)
        function [info, display_idx] = getDisplayInformation(format)
            arguments
                format = "table"
            end
            info = PatternWindowMex("getDisplayModes");
            display_idx = PatternWindowMex("getDisplayIndex");
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
            clear('PatternWindowMex')
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
