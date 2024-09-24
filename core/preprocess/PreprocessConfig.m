classdef PreprocessConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        LoadBackgroundParams = struct("filename", "calibration/StatBackground_20240327_HSSpeed=2_VSSpeed=1.mat")
        BackgroundSubtractionParams = struct('var_name', 'SmoothMean')
        OffsetCorrectionParams = struct("method", "linear_plane", ...
                                        "region_width", 100, ...
                                        "warning", true, ...
                                        "warning_thres_offset", 6, ...
                                        "warning_thres_var", 40)
        OutlierRemovalParams = struct()
    end
    
end
