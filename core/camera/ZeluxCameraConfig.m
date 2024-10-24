classdef ZeluxCameraConfig < BaseObject
    % Configuration file for ZeluxCamera
    
    properties (SetAccess = {?BaseObject})
        Exposure = 0.000694
        ExternalTrigger = true
        XPixels = 1440
        YPixels = 1080
        MaxQueuedFrames = 1
    end

    properties (SetAccess = immutable)
        MaxPixelValue = 1022
    end
    
    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseRunner.struct2obj(s, ZeluxCameraConfig(), varargin{:});
        end
    end

end
