classdef BaseObject < handle
    %BASEOBJECT Base class for all classes in the framework.
    % Provides basic functionality of:
    % 1. converting to and from structures
    % 2. configure the property
    % 3. logging

    properties (SetAccess = immutable, Hidden)
        ConfigurableProp
    end

    methods
        function obj = BaseObject()
            obj.ConfigurableProp = obj.prop("type", "configurable");
        end

        % Converts the object to a structure, iterating over the fields of the object
        function s = struct(obj, fields)
            arguments
                obj
                fields = string(properties(obj))' % Default is all visible properties
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

        % Returns a list of properties as a row vector of string
        function list = prop(obj, options)
            arguments
                obj
                options.type = "non-dependent_visible"
            end
            prop_list = metaclass(obj).PropertyList;
            list = string({prop_list.Name});
            switch options.type
                case "configurable"
                    f = @(p)(~p.Dependent) && (~p.Hidden) && ...
                    ((iscell(p.SetAccess) || (p.SetAccess == "public")));
                case "configurable_constant"
                    f = @(p)(~p.Dependent) && (~p.Hidden) && ((iscell(p.SetAccess) ...
                    || (p.SetAccess == "public")) || (p.SetAccess == "none"));
                case "non-dependent_visible"
                    f = @(p)(~p.Dependent) && (~p.Hidden);
            end
            idx = arrayfun(f, prop_list);
            list = list(idx);
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
                obj.error("Multiple configuration inputs must be in pairs.")
            end
            names = "";
            for i = 1:2:length(args)
                if ismember(args{i}, obj.ConfigurableProp)
                    try
                        obj.(args{i}) = args{i + 1};
                        names = names + " " + args{i};
                    catch me
                        obj.warn2("Error occurs during setting property '%s'\n\t%s", args{i}, me.message)
                    end
                elseif isprop(obj, args{i})
                    obj.warn("%s is not a configurable property.", args{i})
                else
                    obj.warn("%s is not a property of class.", args{i})
                end
            end
            if names ~= ""
                obj.info("Properties configured:%s.", names)
            end
        end

        % Returns the current status label of the object, will be used in
        % info, warning and error logging
        function label = getStatusLabel(obj)
            label = string(class(obj));
        end
    end
    
    % Methods for logging
    methods (Access = protected, Sealed)
        % Logs a message with the current time and the class name
        function info(obj, info, varargin)
            fprintf("[%s] %s: %s\n", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}))
        end

        function info2(obj, info, varargin)
            cprintf('blue', "[%s] %s: %s\n", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
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
                s
                obj = BaseObject()
                options.prop = obj.ConfigurableProp
                options.verbose = true
            end
            args = struct();
            for field = options.prop
                if isfield(s, field)
                    args.(field) = s.(field);
                else
                    obj.warn("Property %s does not exist in structure.", field)
                end
            end
            obj.configProp(args)
            if options.verbose
                obj.info("Object loaded from structure.")
            end
        end
    end

end
