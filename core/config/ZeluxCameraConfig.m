classdef ZeluxCameraConfig < CameraConfig
    %ZELUXCAMERACONFIG
    
    properties (SetAccess = {?ZeluxCamera})
        Exposure = 0.001
        ExternalTrigger = true
        XPixels = 1024
        YPixels = 1024
    end
    
end
