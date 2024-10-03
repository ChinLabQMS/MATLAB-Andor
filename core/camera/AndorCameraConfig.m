classdef AndorCameraConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        Exposure (1, 1) double = 0.2
        ExternalTrigger (1, 1) logical = true
        XPixels (1, 1) double {mustBePositive, mustBeInteger} = 1024
        YPixels (1, 1) double {mustBePositive, mustBeInteger} = 1024
        Cropped (1, 1) logical = false
        FastKinetic (1, 1) logical = false
        FastKineticSeriesLength (1, 1) double {mustBePositive, mustBeInteger} = 2
        HSSpeed (1, 1) {mustBeMember(HSSpeed, [0, 1, 2, 3])} = 2  % Horizontal speed. 0 = 5 MHz, 1 = 3 MHz, 2 = 1 MHz, 3 = 50 kHz
        VSSpeed (1, 1) {mustBeMember(VSSpeed, [0, 1, 2, 3, 4, 5])} = 1  % Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
        MaxPixelValue = 65535
    end

    properties (Dependent)
        FastKineticExposedRows (1, 1) double {mustBePositive, mustBeInteger}
        FastKineticOffset (1, 1) double {mustBePositive, mustBeInteger}
        NumPixels
    end

    methods
        function rows = get.FastKineticExposedRows(obj)
           rows = floor(obj.XPixels / obj.FastKineticSeriesLength);
        end

        function offset = get.FastKineticOffset(obj)
           offset = obj.XPixels - obj.FastKineticExposedRows;
        end

        function num = get.NumPixels(obj)
            num = obj.XPixels * obj.YPixels;
        end
    end

    methods (Static)
        function obj = struct2obj(s)
            obj = BaseObject.struct2obj(s, AndorCameraConfig());
        end

        function obj = file2obj(filename)
            obj = BaseObject.file2obj(filename, AndorCameraConfig());
        end
    end
    
end
