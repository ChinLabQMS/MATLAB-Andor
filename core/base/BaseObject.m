classdef BaseObject < handle
    %BASEOBJECT Base class for all classes in the framework.
    % Provides basic functionality of:
    % 1. converting to and from structures
    % 2. configure the property
    % 3. logging

    methods
        % Converts the object to a structure, iterating over the fields of the object
        function s = struct(obj, fields)
            arguments
                obj
                fields (1, :) string = obj.prop()
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

        % Returns a list of visible properties as a row vector of string
        function list = prop(obj, options)
            arguments
                obj
                options.excluded (1, :) string = string.empty
            end
            list = string(properties(obj))';
            list = list(~ismember(list, options.excluded));
        end
    end
   
    methods (Access = protected, Hidden)
        % Configure the properties
        function configProp(obj, varargin)
            if nargin == 2
                args = varargin{1};
                if isa(args, "struct")
                    args = namedargs2cell(args);
                elseif isa(args, "BaseObject")
                    args = namedargs2cell(args.struct());
                else
                    obj.error("Unreconginized configuration input.")
                end
            elseif rem(length(varargin), 2) == 0
                args = varargin;
            else
                obj.error("Multiple configuration input must be in pairs.")
            end
            for i = 1:2:length(args)
                if ismember(args{i}, obj.prop())
                    try
                        obj.(args{i}) = args{i + 1};
                    catch me
                        obj.warn2("Error occurs during setting property '%s'\n\t%s", args{i}, me.message)
                    end
                else
                    obj.warn("%s is not a valid property.", args{i})
                end
            end
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
            cprintf([179, 98, 5], "[%s] %s: %s\n", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                 obj.getStatusLabel(), sprintf(info, varargin{:}))
        end
        
        % Logs an elevated (red) warning
        function warn2(obj, info, varargin)
            fprintf(2, "[%s] %s: %s\n", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
        end

        % Logs and throw an error with the current time and the class name
        function error(obj, info, varargin)
            error("[%s] %s: %s", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
        end
    end

    methods (Static)
        % Converts a structure to an object, iterating over the fields of the structure
        function obj = struct2obj(s, obj, options)
            arguments
                s (1, 1) struct
                obj (1, 1) BaseObject = BaseObject()
                options.prop_list (1, :) string = obj.prop()
                options.verbose (1, 1) logical = true
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
