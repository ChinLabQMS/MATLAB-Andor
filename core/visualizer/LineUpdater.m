classdef LineUpdater < AxesUpdater

    properties (SetAccess = {?BaseObject})
        CameraName = "Andor19330"
        ImageLabel = "Image"
        Content = "Signal"
        FuncName = "Max"
    end

    properties (SetAccess = protected)
        AddonHandle
    end

    methods
        function config(obj, varargin)
            obj.clear()
            config@AxesUpdater(obj, varargin{:})
        end

        function clear(obj)
            clear@AxesUpdater(obj)
            obj.AddonHandle = [];
        end
    end
    
    methods (Access = protected, Hidden)
        function updateContent(obj, Live)
            % Preserve original hold state upon exit
            c_obj = onCleanup(@()preserveHold(ishold(obj.AxesHandle), obj.AxesHandle));
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
                case "Upper/Lower"
                    x_size = size(data, 1);
                    new = sum(data(1: x_size/2, :), "all") / sum(data((x_size/2 + 1):end, :), "all");
                otherwise
                    if isfield(data, obj.FuncName)
                        new = data.(obj.FuncName);
                    else
                        new = nan;
                        obj.warn2('[%s %s] Not found in live data.', obj.Content, obj.FuncName)
                    end
            end
            % For non-scalar data, directly plot it
            if iscell(new)
                obj.clear()
                if ~iscell(new{1})
                    obj.GraphHandle = plot(obj.AxesHandle, new{1}, "LineWidth", 2);
                else                    
                    switch new{1}{1}
                        case "histogram"
                            obj.GraphHandle = histogram(obj.AxesHandle, 'BinCounts', new{1}{2}, 'BinEdges', new{1}{3});
                            hold(obj.AxesHandle, "on")
                            obj.AddonHandle = xline(obj.AxesHandle, new{1}{4}, '--', 'LineWidth', 2);
                        otherwise
                            obj.error('Unrecognized plot type for line plotter!')
                    end
                end
            else
                % For scalar data, append it after each run
                if isempty(obj.GraphHandle)
                    obj.GraphHandle = plot(obj.AxesHandle, Live.RunNumber, new, "LineWidth", 2);
                    hold(obj.AxesHandle, "on")
                    obj.AddonHandle = plot(obj.AxesHandle, Live.RunNumber, new, "LineWidth", 2, 'LineStyle', '--');
                else
                    obj.GraphHandle.XData = [obj.GraphHandle.XData, Live.RunNumber];
                    obj.GraphHandle.YData = [obj.GraphHandle.YData, new];
                    val = obj.GraphHandle.YData;
                    rolling_mean = mean(val(max(1, length(val) - 4) : end), 'all');
                    obj.AddonHandle.XData = [obj.AddonHandle.XData, Live.RunNumber];
                    obj.AddonHandle.YData = [obj.AddonHandle.YData, rolling_mean];
                end
            end
        end
    end
end
