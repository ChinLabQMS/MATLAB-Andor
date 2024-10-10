classdef AxesRunner < BaseRunner
    
    properties (SetAccess = immutable)
        AxesObj
    end

    properties (SetAccess = protected)
        GraphObj
        AddonObj
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
        end

        function clear(obj)
            cla(obj.AxesObj)
            obj.GraphObj = matlab.graphics.primitive.(obj.Config.Style).empty;
        end

        function uisave(obj)
            if isempty(obj.GraphObj)
                return
            end
            PlotData.XData = obj.GraphObj.XData; 
            PlotData.YData = obj.GraphObj.YData; 
            PlotData.Config = obj.Config.struct(); %#ok<STRNU>
            uisave("PlotData", "PlotData.mat")
        end
    end

    methods (Access = protected)
        function updateImage(obj, data, info)
            if isempty(obj.GraphObj)
                obj.GraphObj = imagesc(obj.AxesObj, data);
                colorbar(obj.AxesObj)
            else
                [x_size, y_size] = size(data);
                obj.GraphObj.XData = [1, y_size];
                obj.GraphObj.YData = [1, x_size];
                obj.GraphObj.CData = data;
            end
            delete(obj.AddonObj)
            switch obj.Config.FuncName
                case "None"
                case "Lattice"
                    Lat = info.Lattice.(obj.Config.CameraName);
                    obj.AddonObj = Lat.plot(prepareSite("hex", "latr", 20), ...
                        'ax', obj.AxesObj, 'x_lim', [1, size(data, 1)], 'y_lim', [1, size(data, 2)]);
                case "PSF"
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
            if isempty(obj.GraphObj)
                obj.GraphObj = plot(obj.AxesObj, info.RunNumber, new, "LineWidth", 2);
            else
                obj.GraphObj.XData = [obj.GraphObj.XData, info.RunNumber];
                obj.GraphObj.YData = [obj.GraphObj.YData, new];
            end
        end
    end

end
