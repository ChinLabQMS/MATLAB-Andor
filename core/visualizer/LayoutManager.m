classdef LayoutManager < BaseObject

    properties (SetAccess = immutable)
        BigAxes1 (1, 1) AxesRunner
        BigAxes2 (1, 1) AxesRunner
        SmallAxes1 (1, 1) AxesRunner
        SmallAxes2 (1, 1) AxesRunner
        SmallAxes3 (1, 1) AxesRunner
    end

    methods
        function obj = LayoutManager(app, config)
            arguments
                app = struct("BigAxes1", matlab.graphics.axis.Axes.empty, ...
                             "BigAxes2", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes1", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes2", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes3", matlab.graphics.axis.Axes.empty)
                config.BigAxes1 = AxesConfig()
                config.BigAxes2 = AxesConfig()
                config.SmallAxes1 = AxesConfig("Line", "Andor19330", "Image", "MaxCount")
                config.SmallAxes2 = AxesConfig("Line", "Andor19330", "Image", "MaxCount")
                config.SmallAxes3 = AxesConfig("Line", "Andor19330", "Image", "MaxCount")
            end
            for field = obj.PropList
                obj.(field) = AxesRunner(app.(field), config.(field));
            end
        end
    
        function update(obj, Live)
            for field = obj.PropList
                obj.(field).update(Live)
            end
        end
    
        function disp(obj)
            fprintf("  %s with properties:\n", class(obj))
            for field = obj.PropList
                fprintf("%12s: AxesRunner%s\n", field,  obj.(field).getStatusLabel())
            end
        end
    end

end