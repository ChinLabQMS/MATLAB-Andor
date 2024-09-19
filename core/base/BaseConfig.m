classdef BaseConfig
    %BASECONFIG Base class for all configuration classes in the framework

    properties (Dependent, Hidden)
        CurrentLabel
    end

    methods
        function s = struct(obj, fields)
            arguments
                obj
                fields (1, :) string = properties(obj)
            end
            s = struct();
            for field = fields
                s.(field{1}) = obj.(field{1});
            end
        end

        function label = getStatusLabel(obj)
            label = "";
        end

        function label = getCurrentLabel(obj)
            label = sprintf("[%s] %s", ...
                            datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                            class(obj));
        end
        
        function label = get.CurrentLabel(obj)
            label = obj.getCurrentLabel() + obj.getStatusLabel();
        end
        
    end

end
