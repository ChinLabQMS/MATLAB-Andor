classdef TestScreen < Projector

    properties (SetAccess = immutable)
        MexFunctionName = "PatternWindowMexTest"
        PixelSize = 7.637
        BMPSizeX = 1920
        BMPSizeY = 1080
        XPixels = 1920
        YPixels = 1080
        DefaultStaticPatternPath = "resources/solid/white.bmp"
    end

end
