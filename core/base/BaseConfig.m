classdef BaseConfig
    %BASECONFIG Base class for all configurations

    properties (Dependent, Hidden)
        CurrentLabel
    end

    methods
        function s = struct(obj)
            fields = properties(obj);
            s = struct();
            for i = 1:length(fields)
                s.(fields{i}) = obj.(fields{i});
            end
        end

        function label = getCurrentLabel(obj)
            label = sprintf("[%s] %s", ...
                            datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                            class(obj));
        end

        function label = get.CurrentLabel(obj)
            label = obj.getCurrentLabel();
        end
    end

end
