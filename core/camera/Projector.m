classdef (Abstract) Projector < BaseConfig

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
        MexHandle
        PixelSize
        PatternSizeX  % BMP size (screen size)
        PatternSizeY  % BMP size
        DefaultStaticPatternPath

        XPixels % Real space pattern size, with dummy pixels
        YPixels % Real space pattern size, with dummy pixels
    end

    properties (Dependent)
        IsWindowCreated
    end

    methods
        function obj = Projector(id)
            arguments
                id = "Test"
            end
            obj.ID = id;
            obj.StaticPatternPath = obj.DefaultStaticPatternPath;
        end

        function set.StaticPatternPath(obj, path)
            obj.loadPattern(path)
            obj.StaticPatternPath = path;
            obj.updateStaticPatternReal()
        end

        function open(obj)
            obj.MexHandle("open")
            obj.StaticPatternPath = obj.StaticPatternPath;
        end

        function close(obj)
            obj.MexHandle("close")
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
        end

        function val = get.IsWindowCreated(obj)
            val = obj.MexHandle("isWindowCreated");
        end
    end

    methods (Access = protected)
        function label = getStatusLabel(obj)
            label = getStatusLabel@BaseConfig(obj) + sprintf("(IsWindowCreated: %d)", obj.IsWindowCreated);
        end

        function loadPattern(obj, path)
            obj.checkFilePath(path, 'StaticPatternPath')
            pattern = imread(path);
            obj.assert(isequal(size(pattern, 1:2), [obj.PatternSizeX, obj.PatternSizeY]), ...
                "Unable to set pattern, dimension (%d, %d) does not match target (%d, %d).", ...
                    size(pattern, 1), size(pattern, 2), obj.PatternSizeX, obj.PatternSizeY)
            if obj.IsWindowCreated
                [status, info] = fileattrib(path);
                if status
                    path = info.Name;
                end
                obj.MexHandle("projectFromFile", string(path))
            end
            obj.StaticPattern = pattern;
            obj.info("Static pattern loaded from '%s'.", path)
        end
    end

    methods (Abstract, Access = protected)
        updateStaticPatternReal(obj)
    end

    methods (Static)
        function info = getDisplayInformation()
            info = struct2table(PatternWindowMex("getDisplayModes"));
        end
    end

end
