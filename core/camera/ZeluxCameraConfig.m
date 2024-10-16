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
            obj = BaseRunner.struct2obj(s, ZeluxCameraConfig(), ...
                "prop_list", ["Exposure", "ExternalTrigger", "XPixels", "YPixels", "MaxPixelValue"]);
        end
    end

end
