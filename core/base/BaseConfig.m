classdef (Abstract) BaseConfig < BaseObject

    methods
        function s = struct(obj)
            s = struct@BaseObject(obj, obj.VisibleProp);
        end
    end

end
