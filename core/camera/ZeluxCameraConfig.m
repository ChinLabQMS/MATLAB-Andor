classdef ZeluxCameraConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        Exposure (1, 1) double = 0.0001
        ExternalTrigger (1, 1) logical = true
        XPixels = 1440
        YPixels = 1080
        MaxPixelValue = 1023
    end

    methods (Static)
        function obj = struct2obj(s)
            obj = BaseObject.struct2obj(s, ZeluxCameraConfig());
        end

        function obj = file2obj(filename)
            obj = BaseObject.file2obj(filename, ZeluxCameraConfig());
        end
    end
    
end
