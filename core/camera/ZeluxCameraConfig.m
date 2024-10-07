classdef ZeluxCameraConfig < BaseObject
    
    properties (SetAccess = {?BaseRunner})
        Exposure (1, 1) double = 0.0001
        ExternalTrigger (1, 1) logical = true
        XPixels = 1440
        YPixels = 1080
        MaxPixelValue = 1022
    end
    
    methods (Static)
        function obj = struct2obj(s)
            obj = BaseObject.struct2obj(s, ZeluxCameraConfig());
        end
    end

end
