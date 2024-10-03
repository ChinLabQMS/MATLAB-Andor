classdef ZeluxCameraConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        Exposure (1, 1) double = 0.0001
        ExternalTrigger (1, 1) logical = true
        XPixels = 1440
        YPixels = 1080
        MaxPixelValue = 1022
    end

    properties (Dependent)
        NumPixels
    end

    methods
        function num = get.NumPixels(obj)
            num = obj.XPixels * obj.YPixels;
        end
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
