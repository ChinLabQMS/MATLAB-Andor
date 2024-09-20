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
                if isa(obj.(field{1}), "BaseConfig")
                    s.(field{1}) = obj.(field{1}).struct();
                else
                    s.(field{1}) = obj.(field{1});
                end
            end
        end

        function label = getStatusLabel(obj) %#ok<MANU>
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

    methods (Static)
        function obj = struct2obj(s, obj)
            arguments
                s (1, 1) struct
                obj (1, 1) BaseConfig = BaseConfig()
            end
            for field = fieldnames(s)'
                try
                    obj.(field{1}) = s.(field{1});
                catch
                    warning("%s: Unable to copy field %s.", obj.CurrentLabel, field{1})
                end
            end
        end
    end

end
