classdef ZeluxCameraConfig < CameraConfig
    %ZELUXCAMERACONFIG
    
    properties (SetAccess = {?Camera})
        Exposure = 0.001
        ExternalTrigger = true
        XPixels = 1080
        YPixels = 1440
    end

    properties (Constant)
        MaxPixelValue = 1023
    end
    
end
