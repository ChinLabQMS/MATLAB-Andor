classdef AxesRunner < BaseRunner
    properties (SetAccess = immutable, Hidden)
        AxesObj
    end

    properties (SetAccess = protected, Hidden)
        GraphObj
    end

    methods
        function obj = AxesRunner(ax, config)
            arguments
                ax = matlab.graphics.axis.Axes.empty
                config (1, 1) AxesConfig = AxesConfig()
            end
            obj@BaseRunner(config)
            obj.AxesObj = ax;
        end

        function update(obj, Live)
            data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
            switch obj.Config.Style
                case "Image"
                    obj.updateImage(data)
                case "Line"                   
                    obj.updateLine(data)
            end
        end

        function clear(obj)
            obj.GraphObj = matlab.graphics.primitive.(obj.Config.Style).empty;
            fprintf("%s: Axes content cleared.\n", obj.CurrentLabel)
        end

        function uisave(obj)
            PlotData.XData = obj.GraphObj.XData; 
            PlotData.YData = obj.GraphObj.YData; 
            PlotData.Config = obj.Config.struct(); %#ok<STRNU>
            uisave("PlotData", "PlotData.mat")
        end

        function label = getStatusLabel(obj)
            label = sprintf(" AxesConfig(Image=[%s,%s], Style=%s, Content=%s)", obj.Config.CameraName, obj.Config.ImageLabel, obj.Config.Style, obj.Config.Content);
        end
    end

    methods (Access = protected)
        function updateImage(obj, data)
            if isempty(obj.GraphObj)
                obj.GraphObj = imagesc(obj.AxesObj, data);
                colorbar(obj.AxesObj)
            else
                [x_size, y_size] = size(data);
                obj.GraphObj.XData = [1, y_size];
                obj.GraphObj.YData = [1, x_size];
                obj.GraphObj.CData = data;
            end
        end

        function updateLine(obj, data)
            switch obj.Config.FuncName
                case "Mean"
                    new = mean(data, "all");
                case "Max"
                    new = max(data, [], "all");
                case "Variance"
                    new = var(data(:), "omitmissing");
                otherwise
                    new = data.(obj.Config.FuncName);
            end
            if isempty(obj.GraphObj)
                obj.GraphObj = plot(obj.AxesObj, new, "LineWidth", 3);
            else
                obj.GraphObj.XData = [obj.GraphObj.XData, obj.GraphObj.XData(end) + 1];
                obj.GraphObj.YData = [obj.GraphObj.YData, new];
            end
        end
    end

end
