classdef PSFCalibrator < LatProcessor & DataProcessor
    %PSFCALIBRATOR Calibrator for
    % 1. Getting PSF calibration
    % 2. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        PSFCameraList = ["Andor19330", "Andor19331", "Zelux"]
        PSFImageLabel = ["Image", "Image", "Pattern_532"]
    end

    properties (Constant)
    end

    properties (SetAccess = protected)
    end

    methods
    end

    methods (Access = protected, Hidden)
        function init(obj)
            
        end
    end

end
