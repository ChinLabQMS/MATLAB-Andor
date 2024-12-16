classdef AndorCameraConfig < BaseConfig
    % Configuration file for AndorCamera
    
    properties (SetAccess = {?BaseObject})
        Exposure = 0.2
        ExternalTrigger = true
        XPixels = 1024
        YPixels = 1024
        Cropped = false
        NumSubFrames = 1
        HSSpeed = 2  % Horizontal speed. 0 = 5 MHz, 1 = 3 MHz, 2 = 1 MHz, 3 = 50 kHz
        VSSpeed = 1  % Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
    end

    properties (SetAccess = immutable)
        MaxPixelValue = 65535
        MaxQueuedFrames = 1
        PixelSize = 13
    end

    properties (Dependent)
        FastKinetic
        FastKineticSeriesLength
        FastKineticExposedRows
        FastKineticOffset
    end

    methods
        function val = get.FastKinetic(obj)
            val = obj.NumSubFrames > 1;
        end

        function val = get.FastKineticSeriesLength(obj)
            val = obj.NumSubFrames;
        end
        
        function val = get.FastKineticExposedRows(obj)
           val = floor(obj.XPixels / obj.NumSubFrames);
        end

        function val = get.FastKineticOffset(obj)
           val = obj.XPixels - obj.FastKineticExposedRows;
        end
    end

    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseObject.struct2obj(s, AndorCameraConfig(), varargin{:});
        end
    end
    
end
