classdef TestScreen < Projector

    properties (SetAccess = immutable)
        PixelSize = 7.637
        PatternSizeX = 1920
        PatternSizeY = 1080
        XPixels = 1920
        YPixels = 1080
        DefaultStaticPatternPath = "calibration/example_pattern/TestScreen_helloworld_1080x1920.bmp"
    end
    
end
