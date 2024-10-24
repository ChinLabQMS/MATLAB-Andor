classdef LatCalibConfig < BaseObject

    properties (SetAccess = {?BaseRunner})
        LatCalibFilePath = "calibration/LatCalib_20241002.mat"
        DataPath = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
    end

    properties (Constant)
        CalibR_BinarizeThres = 0.5
        CalibR_MinBinarizeThres = 30
        CalibR_Bootstrapping = false
        CalibR_PlotDiagnostic = false
        CalibV_RFit = 7
        CalibV_WarnLatNormThres = 0.001
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibO_Sites = Lattice.prepareSite("hex", "latr", 3)
        CalibO_Verbose = false
        CalibO_Debug = false
        CalibO_PlotDiagnostic = false
    end
    
end
