classdef BaseObject < handle
    %BASEOBJECT Base class for all classes in the framework.
    % Provides basic functionality of:
    % 1. Converting to and from structures
    % 2. Configure the property through a protected method
    % 3. Logging

    properties (SetAccess = immutable, Hidden)
        ConfigurableProp
        ParameterProp
        NonDependentProp
        VisibleProp
        AllProp
    end

    methods
        % Update the list of properties as a row vector of string
        function obj = BaseObject()
            prop_list = metaclass(obj).PropertyList;
            list = string({prop_list.Name});
            configurable_idx = arrayfun(@(p)(~p.Dependent) && (~p.Hidden) && ...
                    ((iscell(p.SetAccess) || (p.SetAccess == "public"))), prop_list);
            parameter_idx = arrayfun(@(p)(~p.Dependent) && (~p.Hidden) && ...
                    ((iscell(p.SetAccess) || (p.SetAccess == "public") || (p.SetAccess == "none"))), prop_list);
            nondependent_idx = arrayfun(@(p)(~p.Dependent) && (~p.Hidden), prop_list);
            visible_idx = arrayfun(@(p)(~p.Hidden), prop_list);
            obj.ConfigurableProp = list(configurable_idx);
            obj.ParameterProp = list(parameter_idx);
            obj.NonDependentProp = list(nondependent_idx);
            obj.VisibleProp = list(visible_idx);
            obj.AllProp = list;
        end

        % (Iterative) converts the object to a (value class) structure
        function s = struct(obj, fields, options)
            arguments
                obj
                fields = obj.ParameterProp % Default is all parameters, i.e. constant + configurable
                options.exclude = string.empty
            end
            s = struct();
            for f = fields
                if ismember(f, options.exclude)
                    continue
                end
                if ~isprop(obj, f)
                    obj.warn("[%s] is not a property of class.", f)
                    continue
                end
                if isa(obj.(f), "BaseObject")
                    s.(f) = obj.(f).struct();
                else
                    s.(f) = obj.(f);
                end
            end
        end
    end

    methods (Access = protected, Hidden)
        % Returns the current status label of the object, will be used in
        % info, warning and error logging
        function label = getStatusLabel(obj)
            label = string(class(obj));
        end
    end
   
    methods (Access = protected, Sealed, Hidden)
        % Configure the properties
        function varagout = configProp(obj, varargin)
            struct_input = false;
            if nargin == 2
                args = varargin{1};
                if isa(args, "struct")
                    args = namedargs2cell(args);
                    struct_input = true;
                elseif isa(args, "BaseObject")
                    args = namedargs2cell(args.struct(args.ConfigurableProp));
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
                    if isequal(obj.(args{i}), args{i + 1})
                        continue
                    end
                    try
                        obj.(args{i}) = args{i + 1};
                        names = names + " " + args{i};
                    catch me
                        obj.warn2("Error occurs during setting property [%s]\n\t%s\n", args{i}, me.message)
                        rethrow(me)
                    end
                elseif ~struct_input
                    if isprop(obj, args{i})
                        obj.warn("[%s] is not a configurable property.", args{i})
                    else
                        obj.warn("[%s] is not a property of class.", args{i})
                    end
                end
            end
            names = strip(names);
            if nargout == 1
                varagout = names;
            end
            if struct_input
                obj.info("Properties configured to structured input [%s].", names)
            end
        end
        
        % Check if a path to a file exists
        function varargout = checkFilePath(obj, path, varname, options)
            arguments
                obj
                path
                varname = 'File'
                options.format = "no_backslash"
            end
            if isempty(path)
                obj.error('%s is not set!', varname)
            elseif exist(path, 'file') ~= 2
                obj.error("%s '%s' does not exist!", varname, path)
            end
            if nargout == 0
                return
            end
            varargout{1} = getFullPath(path, "check_exist", true, "format", options.format);
        end

        function str = sinfo(obj, info, varargin)
            str = sprintf("[%s] %s: %s", datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                obj.getStatusLabel(), sprintf(info, varargin{:}));
        end

        % Logs a message with the current time and the class name
        function info(obj, info, varargin)
            fprintf("%s\n", obj.sinfo(info, varargin{:}))
        end
        
        % Blue font
        function info2(obj, info, varargin)
            cprintf('blue', "%s\n", obj.sinfo(info, varargin{:}))
        end

        % Yellow font
        function warn(obj, info, varargin)
            cprintf([179, 98, 5], "%s\n", obj.sinfo(info, varargin{:}))
        end
        
        % Logs an elevated (red) warning
        function warn2(obj, info, varargin)
            fprintf(2, "%s\n", obj.sinfo(info, varargin{:}))
        end

        % Logs and throw an error with the current time and the class name
        function error(obj, info, varargin)
            error("%s", obj.sinfo(info, varargin{:}))
        end
    
        % Assert a certain condition being met
        function assert(obj, condition, info, varargin)
            if ~condition
                obj.error('Assertion error, %s.', sprintf(info, varargin{:}))
            end
        end
    end

    methods (Static)
        % Converts a structure to an object, iterating over the fields of the structure
        function obj = struct2obj(s, obj, fields, options)
            arguments
                s
                obj = BaseObject()
                fields = obj.ConfigurableProp % Properties to set
                options.verbose = true
            end
            args = struct();
            for field = fields
                if isfield(s, field)
                    args.(field) = s.(field);
                else
                    obj.warn("Property [%s] is configurable but does not exist in structure.", field)
                end
            end
            obj.configProp(args)
            if options.verbose
                obj.info("Object created from structure.")
            end
        end
    end

end

function fullpath = getFullPath(path, options)
arguments
    path
    options.check_exist = true
    options.format = "no_back_slash"
end
    fullpath = string(fullfile(pwd, path));
    if options.check_exist
        if exist(fullpath, 'file') ~= 2
           fullpath = string(path);
           if exist(fullpath, 'file') ~= 2
               error('File does not exist! File path: %s', path)
           end
        end
    end
    switch options.format
        case "normal"            
        case "double"
            fullpath = strrep(fullpath, "\", "\\");
        case "no_backslash"
            fullpath = strrep(fullpath, "\", "/");
    end
end
