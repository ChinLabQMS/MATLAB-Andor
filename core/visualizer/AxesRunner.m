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

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            if obj.Config.Style ~= "Image"
                obj.GraphObj = matlab.graphics.primitive.(obj.Config.Style).empty;
            end
        end

        function update(obj, Live)
            data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
            switch obj.Config.Style
                case "Image"
                    if isempty(obj.GraphObj)
                        obj.GraphObj = imagesc(obj.AxesObj, data);
                        colorbar(obj.AxesObj)
                    else
                        [x_size, y_size] = size(data);
                        obj.GraphObj.XData = [1, y_size];
                        obj.GraphObj.YData = [1, x_size];
                        obj.GraphObj.CData = data;
                    end
                case "Line"                   
                    switch obj.Config.FuncName
                        case "Mean"
                            new = mean(data, "all");
                        case "Max"
                            new = max(data, [], "all");
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

        function label = getStatusLabel(obj)
            label = sprintf(" AxesConfig(Image=[%s,%s], Style=%s, Content=%s)", obj.Config.CameraName, obj.Config.ImageLabel, obj.Config.Style, obj.Config.Content);
        end
    end

end
