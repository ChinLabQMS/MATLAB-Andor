classdef PreprocessConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        BackgroundDataPath = "calibration/BkgStat_20240930.mat"
        ProcessCamName = ["Andor19330", "Andor19331"]
        BackgroundSubtraction_VarName = "SmoothMean"
        OffsetCorrection_RegionWidth = 100
        OffsetCorrection_Warning = true
        OffsetCorrection_WarnOffsetThres = 10
        OffsetCorrection_WarnVarThres = 50
        OutlierRemoval_NumMaxPixels = 50
        OutlierRemoval_NumMinPixels = 50
        OutlierRemoval_DiffThres = 50
        OutlierRemoval_Warning = true
    end
    
end
