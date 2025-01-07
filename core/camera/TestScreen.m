classdef TestScreen < Projector

    properties (SetAccess = immutable)
        MexFunctionName = "PatternWindowMexTest"
        PixelSize = 7.637
        BMPSizeX = 1920
        BMPSizeY = 1080
        XPixels = 1920
        YPixels = 1080
        DefaultStaticPatternPath = "calibration/example_pattern/TestScreen_helloworld_1080x1920.bmp"
    end
    
    methods (Access = protected, Hidden)
        function updateStaticPatternReal(obj)
            obj.StaticPatternReal = obj.StaticPattern;
        end
    end

end
