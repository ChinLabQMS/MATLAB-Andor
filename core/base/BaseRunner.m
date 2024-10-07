classdef BaseRunner < BaseObject
    %BASERUNNER Base class for all runners in the framework.
    % Provides basic functionality of setting and displaying configuration.

    properties (SetAccess = immutable)
        Config
    end
    
    methods
        function obj = BaseRunner(config)
            arguments
                config (1, 1) BaseObject = BaseObject()
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
                try
                    obj.Config.(name{i}) = value{i};
                catch
                    obj.warn("Invalid configuration option [%s]", name{i})
                end
            end
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end
    end

end
