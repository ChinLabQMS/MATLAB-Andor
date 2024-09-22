classdef PreprocessConfig < BaseConfig
    
    properties (SetAccess = {?BaseObject, ?BaseConfig})
        InitSequence = ["LoadBackground"]
        ProcessSequence = ["BackgroundSubtraction", "OffsetCorrection"]

        LoadBackgroundParams = struct("file", "calibration/StatBackground_20240327_HSSpeed=2_VSSpeed=1.mat")
        BackgroundSubtractionParams = struct()
        OffsetCorrectionParams = struct("method", "linear_plane", ...
                                        "region_width", 100, ...
                                        "warning", true, ...
                                        "warning_threshold_offset", 6, ...
                                        "warning_threshold_var", 40)
    end
    
end
