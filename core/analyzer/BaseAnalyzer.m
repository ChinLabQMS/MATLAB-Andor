classdef BaseAnalyzer < BaseObject

    methods
        function init(obj)
            obj.runSequence(obj.Config.InitSequence);
            fprintf("%s: %s initialized\n", obj.CurrentLabel, class(obj));
        end

        function process(obj)
            obj.runSequence(obj.Config.ProcessSequence);
        end

    end

    methods (Access = protected)
        function runSequence(obj, sequence)
            for i = 1:length(sequence)
                step = sequence(i);
                params = obj.Config.Params.(step);
                feval("run" + step, obj, params);
            end
        end
        
    end

end
