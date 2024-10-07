classdef BaseObject < handle
    %BASEOBJECT Base class for all classes in the framework.
    % Provides basic functionality of converting to and from structures and logging
    % through a CurrentLabel property.

    methods
        % Converts the object to a structure, iterating over the fields of the object
        function s = struct(obj, fields)
            arguments
                obj
                fields (1, :) string = obj.getPropList()
            end
            s = struct();
            for field = fields
                if isa(obj.(field), "BaseObject")
                    s.(field) = obj.(field).struct();
                else
                    s.(field) = obj.(field);
                end
            end
        end
    end
   
    methods (Access = protected)
        % Returns a list of properties of the object as a row vector of string
        function list = getPropList(obj, options)
            arguments
                obj
                options.excluded = string.empty
            end
            list = string(properties(obj))';
            list = list(~ismember(list, options.excluded));
        end

        % Returns the current status label of the object, will be used in
        % info, warning and error logging
        function label = getStatusLabel(obj)
            label = string(class(obj));
        end
    end

    methods (Access = protected, Sealed)
        % Logs a message with the current time and the class name
        function info(obj, info, varargin)
            fprintf("[%s] %s: %s\n", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
        end

        % Logs a warning with the current time and the class name
        function warn(obj, info, varargin)
            warning('backtrace', 'off')
            warning("[%s] %s: %s", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
            warning('backtrace', 'on')
        end

        % Logs an error with the current time and the class name
        function error(obj, info, varargin)
            error("[%s] %s: %s", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
        end
    end

    methods (Static)
        % Converts a structure to an object, iterating over the fields of the structure
        function obj = struct2obj(s, obj)
            arguments
                s (1, 1) struct
                obj (1, 1) BaseObject = BaseObject()
            end
            for field = string(fields(s))'
                if isprop(obj, field)
                    try
                        obj.(field) = s.(field);
                    catch
                        obj.warn("Invalid field [%s]", field)
                    end
                end
            end
            obj.info("Object loaded from structure.")
        end
    end

end
