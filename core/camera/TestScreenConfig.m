classdef TestScreenConfig < ProjectorConfig
    % Assume normal pixel arrangement

    properties (Constant)
        DefaultStaticPatternPath = "calibration/example_pattern/TestScreen_helloworld_1080x1920.bmp"
    end

    properties (SetAccess = immutable)
        PixelSize = 7.637
        PatternSizeX = 1920
        PatternSizeY = 1080
        XPixels = 1920
        YPixels = 1080
    end

    methods
        function obj = TestScreenConfig()
            obj@ProjectorConfig()
            obj.StaticPatternPath = obj.DefaultStaticPatternPath;
        end
    end

    methods (Access = protected)
        function loadPattern(obj, path)
            loadPattern@ProjectorConfig(obj, path)
            obj.StaticPatternReal = obj.StaticPattern;
        end
    end

end
