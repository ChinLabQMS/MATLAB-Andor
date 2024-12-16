classdef LayoutManager < BaseManager
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
                options.BigAxes1 = @ImageUpdater
                options.BigAxes2 = @ImageUpdater
                options.SmallAxes1 = @LineUpdater
                options.SmallAxes2 = @LineUpdater
                options.SmallAxes3 = @LineUpdater
                options.SmallAxes4 = @LineUpdater
                options.SmallAxes5 = @LineUpdater
            end
            % Bound the fields to axes
            for p = obj.VisibleProp
                if isprop(app, p)
                    obj.(p) = options.(p)(app.(p), p);
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
                if isa(obj.(field), 'LineUpdater')
                    obj.(field).clear()
                end
            end
        end
        
        % Update axes content
        function update(obj, Live, fields, options)
            arguments
                obj
                Live
                fields = obj.VisibleProp
                options.verbose = true
            end
            timer = tic;
            for field = fields
                obj.(field).update(Live)
            end
            if options.verbose
                obj.info("Layout rendered in %.3f s.", toc(timer))
            end
        end
    end

end
