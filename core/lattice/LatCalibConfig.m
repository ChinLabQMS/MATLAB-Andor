classdef LatCalibConfig < BaseObject

    properties (SetAccess = {?BaseRunner})
        LatCalibFilePath = "calibration/LatCalib_20241002.mat"
        DataPath = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
        CalibV_RFit = 7
        CalibR_BinarizeThres = -100
        CalibR_OutlierThres = 2000
    end

end
