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
            camera = obj.Config.CameraName;
            label = obj.Config.ImageLabel;
            content = obj.Config.Content;
            style = obj.Config.Style;
            switch style
                case "Image"
                    data = Live.(content).(camera).(label);
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
                    
            end
        end

        function label = getStatusLabel(obj)
            label = sprintf(" AxesConfig(Image=[%s,%s], Style=%s, Content=%s)", obj.Config.CameraName, obj.Config.ImageLabel, obj.Config.Style, obj.Config.Content);
        end
    end

end
