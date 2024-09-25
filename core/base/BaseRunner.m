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
                obj.Config.(name{i}) = value{i};
                % try
                %     fprintf('%s: %s set to %s.\n', obj.CurrentLabel, name{i}, string(value{i}))
                % catch
                % end
            end
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end
    end

end
