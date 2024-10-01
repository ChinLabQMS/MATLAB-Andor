classdef LatPreCalibGeneratorConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        DataPath = "data/2024/09 September/20240930 multilayer/FK2_focused_to_major_layer.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
    end

end
