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
        function updateContent(obj, data, sequencer)
            switch obj.Config.FuncName
                case "Mean"
                    new = mean(data, "all");
                case "Max"
                    new = max(data, [], "all");
                case "Variance"
                    new = var(data(:));
                otherwise
                    try
                        new = reshape(data.(obj.Config.FuncName), [], 1);
                    catch
                        new = nan;
                        obj.warnLabel(obj.Config.Content, obj.Config.FuncName, 'Not found in data.')
                    end
            end
            if isempty(obj.GraphHandle)
                obj.GraphHandle = plot(obj.AxesHandle, sequencer.RunNumber, new, "LineWidth", 2);
            else
                obj.GraphHandle.XData = [obj.GraphHandle.XData, sequencer.RunNumber];
                obj.GraphHandle.YData = [obj.GraphHandle.YData, new];
            end
        end
    end

end
