classdef ZeluxCameraConfig < BaseConfig
    
    properties (SetAccess = {?BaseObject, ?BaseConfig})
        Exposure (1, 1) double = 0.00001
        ExternalTrigger (1, 1) logical = true
        XPixels = 1440
        YPixels = 1080
    end

    properties (Constant)
        MaxPixelValue = 1023
    end

    methods (Static)
        function obj = struct2obj(s)
            obj = BaseConfig.struct2obj(s, ZeluxCameraConfig());
        end
    end
    
end
