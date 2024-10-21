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
                catch me
                    obj.warn2("Error occurs during setting property '%s'\n\t%s", name{i}, me.message)
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
                options.prop_list = obj.getPropList()
                options.verbose = true
            end
            for field = options.prop_list
                if isfield(s, field)
                    try
                        obj.(field) = s.(field);
                    catch me
                        obj.warn2("Error occurs during setting property '%s'\n\t%s", field, me.message)
                    end
                end
            end
            if options.verbose
                obj.info("Object loaded from structure.")
            end
        end
    end
    
end
