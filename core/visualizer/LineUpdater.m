classdef LineUpdater < AxesUpdater

    properties (SetAccess = {?BaseObject})
        CameraName = "Andor19330"
        ImageLabel = "Image"
        Content = "Signal"
        FuncName = "Max"
    end

    methods
        function config(obj, varargin)
            obj.clear()
            config@AxesUpdater(obj, varargin{:})
        end
    end
    
    methods (Access = protected, Hidden)
        function updateContent(obj, Live)
            data = Live.(obj.Content).(obj.CameraName).(obj.ImageLabel);
            switch obj.FuncName
                case "Mean"
                    new = mean(data, "all");
                case "Max"
                    new = max(data, [], "all");
                case "Sum"
                    new = sum(data, 'all');
                case "Variance"
                    new = var(data(:));
                otherwise
                    if isfield(data, obj.FuncName)
                        new = reshape(data.(obj.FuncName), [], 1);
                    else
                        new = nan;
                        obj.warn2('[%s %s] Not found in live data.', obj.Content, obj.FuncName)
                    end
            end
            if isempty(obj.GraphHandle)
                obj.GraphHandle = plot(obj.AxesHandle, Live.RunNumber, new, "LineWidth", 2);
            else
                obj.GraphHandle.XData = [obj.GraphHandle.XData, Live.RunNumber];
                obj.GraphHandle.YData = [obj.GraphHandle.YData, new];
            end
        end
    end

end
