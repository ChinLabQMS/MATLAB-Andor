classdef PreprocessConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        BackgroundFileLocation = "calibration/BkgStat_20240930.mat"
        
        BackgroundSubtractionParams = struct('var_name', 'SmoothMean')
        OffsetCorrectionParams = struct("method", "linear_plane", ...
                                        "region_width", 100, ...
                                        "warning", true, ...
                                        "warning_thres_offset", 10, ...
                                        "warning_thres_var", 50)
        OutlierRemovalParams = struct()
    end
    
end
