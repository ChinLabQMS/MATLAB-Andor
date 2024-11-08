classdef ZeluxCameraConfig < CameraConfig
    % Configuration file for ZeluxCamera
    
    properties (SetAccess = {?BaseObject})
        Exposure = 0.000694
        ExternalTrigger = true
        MaxQueuedFrames = 1
    end

    properties (SetAccess = immutable)
        XPixels = 1440
        YPixels = 1080
        MaxPixelValue = 1022
        NumSubFrames = 1
    end

    methods
        function s = struct(obj)
            s = struct@BaseObject(obj.AllProp);
        end
    end
    
    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseObject.struct2obj(s, ZeluxCameraConfig(), varargin{:});
        end
    end

end
