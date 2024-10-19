classdef ZeluxCameraConfig < BaseObject
    
    properties (SetAccess = {?BaseRunner})
        Exposure (1, 1) double = 0.0001
        ExternalTrigger (1, 1) logical = true
        XPixels = 1440
        YPixels = 1080
        MaxPixelValue = 1022
    end

    properties (Dependent, Hidden)
        NumFrames (1, 1) double {mustBePositive, mustBeInteger}
    end

    methods
        function val = get.NumFrames(obj)
            val = 1;
        end
    end
    
    methods (Static)
        function obj = struct2obj(s)
            obj = BaseRunner.struct2obj(s, ZeluxCameraConfig());
        end
    end

end
