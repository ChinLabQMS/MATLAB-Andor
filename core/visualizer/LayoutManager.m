classdef LayoutManager < BaseObject

    properties (SetAccess = immutable)
        BigAxes1 (1, 1) AxesRunner
        BigAxes2 (1, 1) AxesRunner
        SmallAxes1 (1, 1) AxesRunner
        SmallAxes2 (1, 1) AxesRunner
        SmallAxes3 (1, 1) AxesRunner
        SmallAxes4 (1, 1) AxesRunner
        SmallAxes5 (1, 1) AxesRunner
    end

    methods
        function obj = LayoutManager(app, config)
            arguments
                app = struct("BigAxes1", matlab.graphics.axis.Axes.empty, ...
                             "BigAxes2", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes1", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes2", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes3", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes4", matlab.graphics.axis.Axes.empty, ...
                             "SmallAxes5", matlab.graphics.axis.Axes.empty)
                config.BigAxes1 = AxesConfig("style", "Image")
                config.BigAxes2 = AxesConfig("style", "Image")
                config.SmallAxes1 = AxesConfig("style", "Line")
                config.SmallAxes2 = AxesConfig("style", "Line")
                config.SmallAxes3 = AxesConfig("style", "Line")
                config.SmallAxes4 = AxesConfig("style", "Line")
                config.SmallAxes5 = AxesConfig("style", "Line")
            end
            for field = obj.PropList
                obj.(field) = AxesRunner(app.(field), config.(field));
            end
        end
    
        function update(obj, Live, options)
            arguments
                obj
                Live (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            for field = obj.PropList
                obj.(field).update(Live)
            end
            drawnow
            if options.verbose
                fprintf("%s: Layout rendered in %.3f s.\n", obj.CurrentLabel, toc(timer))
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