classdef AndorCameraConfig < BaseConfig
    
    properties (SetAccess = {?BaseObject, ?BaseConfig})
        Exposure (1, 1) double = 0.2
        ExternalTrigger (1, 1) logical = true
        XPixels (1, 1) double {mustBePositive, mustBeInteger} = 1024
        YPixels (1, 1) double {mustBePositive, mustBeInteger} = 1024
        Cropped (1, 1) logical = false
        FastKinetic (1, 1) logical = false
        FastKineticSeriesLength (1, 1) double {mustBePositive, mustBeInteger} = 2
        FastKineticExposedRows (1, 1) double {mustBePositive, mustBeInteger} = 512
        FastKineticOffset (1, 1) double {mustBePositive, mustBeInteger} = 512
        HSSpeed (1, 1) {mustBeMember(HSSpeed, [0, 1, 2, 3])} = 2  % Horizontal speed. 0 = 5 MHz, 1 = 3 MHz, 2 = 1 MHz, 3 = 50 kHz
        VSSpeed (1, 1) {mustBeMember(VSSpeed, [0, 1, 2, 3, 4, 5])} = 1  % Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
    end

    properties (Constant)
        MaxPixelValue = 65535
    end

    methods (Static)
        function obj = struct2obj(s)
            obj = BaseConfig.struct2obj(s, AndorCameraConfig());
        end
    end
    
end