classdef (Abstract) Projector < BaseConfig

    properties (SetAccess = immutable)
        ID
        MexHandle
    end

    properties (SetAccess = {?BaseObject})
        StaticPatternPath
    end

    properties (SetAccess = protected)
        StaticPattern
        StaticPatternReal
    end

    properties (Abstract, SetAccess = immutable)
        MexFunctionName
        PixelSize % In um
        BMPSizeX  % BMP size
        BMPSizeY  % BMP size
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
            clear(obj.MexFunctionName)
            obj.MexHandle = str2func(obj.MexFunctionName);
            obj.MexHandle("lock")
            obj.ID = id;
            obj.StaticPatternPath = obj.DefaultStaticPatternPath;
        end

        function set.StaticPatternPath(obj, path)
            obj.loadPattern(path)
            obj.StaticPatternPath = path;
            obj.updateStaticPatternReal()
        end

        function open(obj, verbose)
            arguments
                obj
                verbose = false
            end
            obj.MexHandle("open", verbose)
            obj.StaticPatternPath = obj.StaticPatternPath;
        end

        function close(obj, verbose)
            arguments
                obj 
                verbose = false
            end
            obj.MexHandle("close", verbose)
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
            obj.MexHandle("unlock")
        end

        function val = get.IsWindowCreated(obj)
            val = obj.MexHandle("isWindowCreated");
        end
    end

    methods (Access = protected)
        function label = getStatusLabel(obj)
            label = getStatusLabel@BaseConfig(obj) + sprintf("(WindowOpen: %d)", obj.IsWindowCreated);
        end

        function loadPattern(obj, path)
            obj.checkFilePath(path, 'StaticPatternPath')
            pattern = imread(path);
            obj.assert(isequal(size(pattern, 1:2), [obj.BMPSizeX, obj.BMPSizeY]), ...
                "Unable to set pattern, dimension (%d, %d) does not match target (%d, %d).", ...
                size(pattern, 1), size(pattern, 2), obj.BMPSizeX, obj.BMPSizeY)
            % [resolved_path] = resolvePath(path);
            % disp(path)
            % disp(resolved_path)
            % obj.MexHandle("setStaticPatternPath", string(resolved_path))
            obj.StaticPattern = pattern;
            obj.info("Static pattern loaded from '%s'.", path)
        end
    end

    methods (Abstract, Access = protected)
        updateStaticPatternReal(obj)
    end

    methods (Static)
        function info = getDisplayInformation(format)
            arguments
                format = "table"
            end
            info = PatternWindowMex("getDisplayModes");
            switch format
                case "struct"
                case "table"
                    info = struct2table(info);
                case "string"
                    strarr = strings(3, 1);
                    for i = 1: length(info)
                        strarr(i) = sprintf("Display#%d: %d x %d, %.1f Hz", ...
                            i, info(i).Width, info(i).Height, info(i).RefreshRate);
                    end
                    info = strarr;
                otherwise
                    error('Unknown format for display information!')
            end
        end
    end

end
