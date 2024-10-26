classdef AxesRunner < BaseRunner
    %AXESRUNNER Runner for updating axes with live data
    
    properties (SetAccess = immutable)
        AxesHandle
    end

    properties (SetAccess = protected)
        GraphHandle
        AddonHandle
        Live = struct.empty
    end

    methods
        function obj = AxesRunner(ax, config)
            arguments
                ax = matlab.graphics.axis.Axes.empty
                config (1, 1) AxesConfig = AxesConfig()
            end
            obj@BaseRunner(config)
            obj.AxesHandle = ax;
        end

        function update(obj, Live)
            obj.Live = Live;
            try
                data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
            catch
                obj.warn("[%s %s] Not found in Live.", obj.Config.CameraName, obj.Config.ImageLabel)
                return
            end
            info = Live.Info;
            switch obj.Config.Style
                case "Image"
                    obj.updateImage(data, info)
                case "Line"                   
                    obj.updateLine(data, info)
            end
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            if obj.Config.Style == "Line"
                obj.clear()
            end
            if ~isempty(obj.Live)
                obj.update(obj.Live)
            end
        end

        function clear(obj)
            cla(obj.AxesHandle)
            obj.GraphHandle = matlab.graphics.primitive.(obj.Config.Style).empty;
        end

        function uisave(obj)
            if isempty(obj.GraphHandle)
                return
            end
            PlotData.XData = obj.GraphHandle.XData; 
            PlotData.YData = obj.GraphHandle.YData; 
            PlotData.Config = obj.Config.struct(); %#ok<STRNU>
            uisave("PlotData", "PlotData.mat")
        end
    end

    methods (Access = protected)
        function updateImage(obj, data, info)
            if isempty(obj.GraphHandle)
                obj.GraphHandle = imagesc(obj.AxesHandle, data);
                colorbar(obj.AxesHandle)
            else
                [x_size, y_size] = size(data);
                obj.GraphHandle.XData = [1, y_size];
                obj.GraphHandle.YData = [1, x_size];
                obj.GraphHandle.CData = data;
            end
            delete(obj.AddonHandle)
            switch obj.Config.FuncName
                case "None"
                case "Lattice"
                    Lat = info.Lattice.(obj.Config.CameraName);
                    obj.AddonHandle = Lat.plot(obj.AxesHandle, Lattice.prepareSite("hex", "latr", 20), ...
                        'x_lim', [1, size(data, 1)], 'y_lim', [1, size(data, 2)]);
                case "Lattice All"
            end
        end

        function updateLine(obj, data, info)
            switch obj.Config.FuncName
                case "Mean"
                    new = mean(data, "all");
                case "Max"
                    new = max(data, [], "all");
                case "Variance"
                    new = var(data(:));
                otherwise
                    new = reshape(data.(obj.Config.FuncName), [], 1);
            end
            if isempty(obj.GraphHandle)
                obj.GraphHandle = plot(obj.AxesHandle, info.RunNumber, new, "LineWidth", 2);
            else
                obj.GraphHandle.XData = [obj.GraphHandle.XData, info.RunNumber];
                obj.GraphHandle.YData = [obj.GraphHandle.YData, new];
            end
        end
    end

end
