classdef LineRunner < AxesRunner

    methods
        function init(obj)
            obj.clear()
        end

        function config(obj, varargin)
            obj.clear()
            config@AxesRunner(obj, varargin{:})
        end
    end
    
    methods (Access = protected)
        function updateContent(obj, data, info)
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
