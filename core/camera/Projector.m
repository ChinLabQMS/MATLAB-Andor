classdef (Abstract) Projector < BaseProcessor

    properties (SetAccess = immutable)
        ID
        MexHandle
    end

    properties (SetAccess = protected)
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
        IsWindowMinimized
        StaticPatternPath
        StaticPatternRaw
    end

    methods
        function obj = Projector(id)
            arguments
                id = "Test"
            end
            obj@BaseProcessor()
            obj.MexHandle = str2func(obj.MexFunctionName);
            obj.MexHandle("lock")
            obj.ID = id;
            obj.setStaticPatternPath(obj.DefaultStaticPatternPath)
        end
        
        function setStaticPatternPath(obj, path)
            obj.checkFilePath(path, 'StaticPatternPath');
            obj.MexHandle("setStaticPatternPath", path, false)
            obj.info("Static pattern loaded from '%s'.", path)
        end

        function open(obj, verbose)
            arguments
                obj
                verbose = false
            end
            obj.MexHandle("open", verbose)
        end

        function close(obj, verbose)
            arguments
                obj 
                verbose = false
            end
            obj.MexHandle("close", verbose)
        end

        function setDisplayIndex(obj, index, verbose)
            arguments
                obj
                index = -1
                verbose = false
            end
            obj.MexHandle("setDisplayIndex", index, verbose)
        end

        function selectPatternFromFile(obj)
            [file, location] = uigetfile('*.bmp', 'Select a BMP pattern to display');
            if file ~= 0
                obj.setStaticPatternPath(fullfile(location, file));
            end
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
            clear(obj.MexFunctionName)
        end

        function val = get.IsWindowCreated(obj)
            val = obj.MexHandle("isWindowCreated");
        end

        function val = get.IsWindowMinimized(obj)
            val = obj.MexHandle("isWindowMinimized");
        end

        function val = get.StaticPatternPath(obj)
            val = string(obj.MexHandle("getStaticPatternPath"));
        end

        function val = get.StaticPatternRaw(obj)
            try
                val = obj.MexHandle("getStaticPattern");
            catch
                val = [];
            end
        end
    end

    methods (Access = protected)
        function init(obj)
            clear(obj.MexFunctionName)
        end

        function label = getStatusLabel(obj)
            label = getStatusLabel@BaseProcessor(obj) + sprintf("(WindowOpen: %d)", obj.IsWindowCreated);
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
