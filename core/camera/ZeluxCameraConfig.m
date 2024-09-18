classdef ZeluxCameraConfig < BaseConfig
    
    properties (SetAccess = {?BaseObject})
        Exposure = 0.001
        ExternalTrigger = true
        XPixels = 1440
        YPixels = 1080
    end

    properties (Constant)
        MaxPixelValue = 1023
    end
    
end
