classdef BaseObject < handle
    %BASEOBJECT Base class for all classes in the framework.
    % Provides basic functionality of converting to and from structures and logging
    % through a CurrentLabel property.

    properties (Dependent, Hidden)
        CurrentLabel
    end

    methods
        function s = struct(obj, fields)
            arguments
                obj
                fields (1, :) string = string(properties(obj)')
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

        function save(obj, filename, options)
            arguments
                obj
                filename (1, 1) string = class(obj) + ".mat"
                options.struct_export (1, 1) logical = false
            end
            Data = obj.struct();
            if ~options.struct_export
                save(filename, '-struct', 'Data');
            else
                save(filename, 'Data');
            end
            fprintf('%s: %s saved to file %s.\n', obj.CurrentLabel, class(obj), filename)
        end

        function uisave(obj, filename)
            arguments
                obj
                filename (1, 1) string = class(obj) + ".mat"
            end
            Data = obj.struct(); %#ok<NASGU>
            uisave('Data', filename);
            fprintf('%s: %s saved to file %s.\n', obj.CurrentLabel, class(obj), filename)
        end

        function label = getStatusLabel(obj) %#ok<MANU>
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

    methods (Static)
        function obj = struct2obj(s, obj)
            arguments
                s (1, 1) struct
                obj (1, 1) BaseObject = BaseObject()
            end
            for field = fieldnames(s)'
                if isprop(obj, field{1})
                    try
                        obj.(field{1}) = s.(field{1});
                    catch
                        warning("%s: Unable to copy field %s.", obj.CurrentLabel, field{1})
                    end
                end
            end
            fprintf('%s: %s loaded from structure.\n', obj.CurrentLabel, class(obj))
        end

        function obj = file2obj(filename, obj)
            arguments
                filename (1, 1) string
                obj (1, 1) BaseObject = BaseObject()
            end
            if isfile(filename)
                s = load(filename);
                obj = BaseObject.struct2obj(s, obj);
            else
                error("%s: File %s does not exist.", obj.CurrentLabel, filename)
            end
        end
    end

end
