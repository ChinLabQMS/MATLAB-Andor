classdef DMDConfig < ProjectorConfig
    % Assume diamond pixel arrangement

    properties (Constant)
        DefaultStaticPatternPath = "calibration/example_pattern/DMD_RGB.bmp"
    end
   
    properties (SetAccess = immutable)
        PixelSize = 7.637
        PatternSizeX = 1140
        PatternSizeY = 912
        XPixels = 1482
        YPixels = 1481
    end
    
    methods
        function obj = DMDConfig()
            obj@ProjectorConfig()
            obj.StaticPatternPath = obj.DefaultStaticPatternPath;
        end
    end

    methods (Access = protected)
        function updateStaticPatternPath(obj, path)
            updateStaticPatternPath@ProjectorConfig(obj, path)
        end
    end

end
