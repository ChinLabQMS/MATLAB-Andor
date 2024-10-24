classdef AndorCameraConfig < BaseObject
    % Configuration file for AndorCamera
    
    properties (SetAccess = {?BaseObject})
        Exposure = 0.2
        ExternalTrigger = true
        XPixels = 1024
        YPixels = 1024
        Cropped = false
        FastKinetic = false
        FastKineticSeriesLength = 2
        HSSpeed = 2  % Horizontal speed. 0 = 5 MHz, 1 = 3 MHz, 2 = 1 MHz, 3 = 50 kHz
        VSSpeed = 1  % Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
    end

    properties (SetAccess = immutable)
        MaxPixelValue = 65535
        MaxQueuedFrames = 1
    end

    properties (Dependent, Hidden)
        FastKineticExposedRows
        FastKineticOffset
        NumSubFrames
    end

    methods
        function rows = get.FastKineticExposedRows(obj)
           rows = floor(obj.XPixels / obj.FastKineticSeriesLength);
        end

        function offset = get.FastKineticOffset(obj)
           offset = obj.XPixels - obj.FastKineticExposedRows;
        end

        function val = get.NumSubFrames(obj)
            if obj.FastKinetic
                val = obj.FastKineticSeriesLength;
            else
                val = 1;
            end
        end
    end

    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseRunner.struct2obj(s, AndorCameraConfig(), varargin{:});
        end
    end
    
end
