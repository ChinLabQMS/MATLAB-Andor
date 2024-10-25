classdef LayoutManager < BaseObject
    %LAYOUTMANAGER Manage layout of axes for visualization

    properties (SetAccess = immutable)
        BigAxes1
        BigAxes2
        SmallAxes1
        SmallAxes2
        SmallAxes3
        SmallAxes4
        SmallAxes5
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
                Live
                fields = obj.prop()
                options.verbose = false
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