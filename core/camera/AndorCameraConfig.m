classdef AndorCameraConfig < CameraConfig
    %ANDORCAMERACONFIG
    
    properties (SetAccess = {?Camera})
        Exposure = 0.2
        ExternalTrigger = true
        XPixels = 1024
        YPixels = 1024
        Cropped (1, 1) logical = false
        FastKinetic (1, 1) logical = false
        FastKineticSeriesLength (1, 1) double = 2
        FastKineticExposedRows (1, 1) double = 512
        FastKineticOffset (1, 1) double = 512
        HSSpeed = 2 % Horizontal speed. 0 = 5 MHz, 1 = 3 MHz, 2 = 1 MHz, 3 = 50 kHz
        VSSpeed = 1 % Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
    end

    properties (Constant)
        MaxPixelValue = 65535
    end
    
end
