classdef LayoutManager < BaseObject
    %LAYOUTMANAGER Manage layout of axes for visualization

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
                app = []
                config.BigAxes1 = AxesConfig("style", "Image", "func", "None")
                config.BigAxes2 = AxesConfig("style", "Image", "func", "None")
                config.SmallAxes1 = AxesConfig("style", "Line")
                config.SmallAxes2 = AxesConfig("style", "Line")
                config.SmallAxes3 = AxesConfig("style", "Line")
                config.SmallAxes4 = AxesConfig("style", "Line")
                config.SmallAxes5 = AxesConfig("style", "Line")
            end
            % Bound the fields to axes
            for p = obj.prop()
                if isprop(app, p)
                    obj.(p) = AxesRunner(app.(p), config.(p));
                else
                    obj.warn("Field %s is not a valid property of app.", p)
                end
            end
        end

        % Clear all line plots
        function init(obj, fields)
            arguments
                obj
                fields = obj.prop()
            end
            for field = fields
                if obj.(field).Config.Style == "Line"
                    obj.(field).clear()
                end
            end
        end
        
        % Update axes content
        function update(obj, Live, fields, options)
            arguments
                obj
                Live (1, 1) struct
                fields = obj.prop()
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            for field = fields
                obj.(field).update(Live)
            end
            drawnow
            if options.verbose
                obj.info("Layout rendered in %.3f s.", toc(timer))
            end
        end
    end

end