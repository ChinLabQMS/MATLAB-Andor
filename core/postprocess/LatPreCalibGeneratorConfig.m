classdef LatPreCalibGeneratorConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        DataPath = "data\2024\05 May\2024-05-22\calibration_test_40shots.mat"
        CameraList = ["Andor19330", "Andor19331"]
        ImageLabel = ["Image", "Image"]

        % CameraList = ["Andor19330", "Andor19331", "Zelux"]
        % ImageLabel = ["Image", "Image", "Lattice"]
    end

end
