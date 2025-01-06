classdef DMD < Projector
    
    properties (SetAccess = immutable)
        MexHandle = @PatternWindowMex
        PixelSize = 7.637
        BMPSizeX = 1140
        BMPSizeY = 912
        XPixels = 1482
        YPixels = 1481
        DefaultStaticPatternPath = "calibration/example_pattern/DMD_RGB.bmp"
    end

    methods (Access = protected, Hidden)
        function updateStaticPatternReal(obj)
            obj.StaticPatternReal = obj.StaticPattern;
        end
    end

end
