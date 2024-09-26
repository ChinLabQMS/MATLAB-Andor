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
            func = obj.Config.FuncName;
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
                    data = Live.Processed.(camera).(label);
                    new = 0;
                    switch func
                        case "Mean"
                            new = mean(data, "all");
                        case "Max"
                            new = max(data, [], "all");
                        case "Gaussian X Center"
                        case "Gaussian Y Center"
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
