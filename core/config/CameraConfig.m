classdef (Abstract) CameraConfig
    %CAMERACONFIG
    
    properties (Abstract, SetAccess = {?Camera})
        Exposure (1, 1) double
        ExternalTrigger (1, 1) logical
        XPixels (1, 1) double
        YPixels (1, 1) double
    end

end
