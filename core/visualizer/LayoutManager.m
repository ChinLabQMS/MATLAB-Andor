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
        function obj = LayoutManager(app, options)
            arguments
                app = []
                options.BigAxes1 = @ImageRunner
                options.BigAxes2 = @ImageRunner
                options.SmallAxes1 = @LineRunner
                options.SmallAxes2 = @LineRunner
                options.SmallAxes3 = @LineRunner
                options.SmallAxes4 = @LineRunner
                options.SmallAxes5 = @LineRunner
            end
            % Bound the fields to axes
            for p = obj.VisibleProp
                if isprop(app, p)
                    obj.(p) = options.(p)(app.(p));
                else
                    obj.warn("Field %s is not a valid property of app.", p)
                end
            end
        end

        % Clear all line plots
        function init(obj, fields)
            arguments
                obj
                fields = obj.VisibleProp
            end
            for field = fields
                obj.(field).init()
            end
        end
        
        % Update axes content
        function update(obj, sequencer, fields, options)
            arguments
                obj
                sequencer
                fields = obj.VisibleProp
                options.verbose = true
            end
            timer = tic;
            for field = fields
                obj.(field).update(sequencer)
            end
            if options.verbose
                obj.info("Layout rendered in %.3f s.", toc(timer))
            end
        end
    end

end
