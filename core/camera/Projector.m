classdef (Abstract) Projector < BaseProcessor

    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = {?BaseObject})
        OperationMode = "static"
        StaticPatternPath
    end

    properties (SetAccess = protected)
        StaticPattern
        StaticPatternReal
    end

    properties (Abstract, SetAccess = immutable)
        PixelSize
        PatternSizeX
        PatternSizeY
        XPixels
        YPixels
        DefaultStaticPatternPath
    end

    methods
        function obj = Projector(id)
            arguments
                id = "Test"
            end
            obj@BaseProcessor()
            obj.ID = id;
            obj.StaticPatternPath = obj.DefaultStaticPatternPath;
        end

        function set.StaticPatternPath(obj, path)
            obj.loadPattern(path)
            obj.StaticPatternPath = path;
        end

        function close(obj)
        end

        function plot(obj)
            figure
            subplot(1, 2, 1)
            imagesc(obj.StaticPattern)
            axis image
            subplot(1, 2, 2)
            imagesc(obj.StaticPatternReal)
            axis image
        end

        function delete(obj)
            obj.close()
            delete@BaseProcessor(obj)
        end
    end

    methods (Access = protected)
        function loadPattern(obj, path)
            pattern = imread(path);
            obj.assert(isequal(size(pattern, 1:2), [obj.PatternSizeX, obj.PatternSizeY]), ...
                "Unable to set pattern, dimension (%d, %d) does not match target (%d, %d).", ...
                    size(pattern, 1), size(pattern, 2), obj.PatternSizeX, obj.PatternSizeY)
            obj.StaticPattern = pattern;
            obj.info("Static pattern loaded from '%s'.", path)
        end
    end

end
