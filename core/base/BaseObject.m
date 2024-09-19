classdef BaseObject < handle
    %BASEOBJECT Base class for all objects in the framework
    % Provides basic functionality of logging and configuration.

    properties (SetAccess = protected)
        Config
    end

    properties (Dependent, Hidden)
        CurrentLabel
    end
    
    methods
        function obj = BaseObject(config)
            arguments
                config = BaseConfig()
            end
            obj.Config = config;
        end

        function config(obj, name, value)
            arguments
                obj
            end
            arguments (Repeating)
                name
                value
            end
            for i = 1:length(name)
                obj.Config.(name{i}) = value{i};
            end
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
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
