classdef Projector < BaseProcessor
    
    properties (Constant)
        XPixels = 1482
        YPixels = 1481
    end

    properties (SetAccess = {?BaseObject})
        PatternPath
    end
    
    properties (SetAccess = protected)
        Pattern
    end

    methods
        function set.PatternPath(obj, path)
            obj.loadPattern(path)
            obj.PatternPath = path;
        end
    end

    methods (Access = protected)
        function loadPattern(obj, path)
            pattern = imread(path);
            if isequal(size(pattern), [obj.XPixels, obj.YPixels])
                obj.Pattern = pattern;
            else
                obj.error("Unable to set pattern, dimension (%d, %d) does not match target (%d, %d).", ...
                    size(pattern, 1), size(pattern, 2), obj.XPixels, obj.YPixels)
            end
        end
    end

end
