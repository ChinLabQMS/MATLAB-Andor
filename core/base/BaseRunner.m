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

    methods (Static)
        % Converts a structure to an object, iterating over the fields of the structure
        function obj = struct2obj(s, obj, options)
            arguments
                s (1, 1) struct
                obj (1, 1) BaseObject = BaseObject()
                options.prop_list = string(fields(s))'
            end
            for field = options.prop_list
                if isprop(obj, field)
                    try
                        obj.(field) = s.(field);
                    catch me
                        obj.warn("Invalid field [%s], %s", field, getReport(me, 'extended', 'hyperlinks', 'on'))
                    end
                end
            end
            obj.info("Object loaded from structure.")
        end
    end
    
end
