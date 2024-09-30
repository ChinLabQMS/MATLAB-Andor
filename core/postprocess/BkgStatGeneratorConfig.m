classdef BkgStatGeneratorConfig < BaseObject

    properties (SetAccess = {?BaseObject})
        DataPath = "data/2024/09 September/20240926 camera readout noise/"
        Full_1MHz = "clean_bg_1MHz.mat"
        Full_3MHz = "clean_bg_3MHz.mat"
        Full_5MHz = "clean_bg_5MHz.mat"
        Cropped_1MHz = "clean_bg_1MHz_cropped.mat"
        Cropped_3MHz = "clean_bg_3MHz_cropped.mat"
        Cropped_5MHz = "clean_bg_5MHz_cropped.mat"

        CameraList = ["Andor19330", "Andor19331"]
        ImageLabel = "Image"
        SettingList = ["Full_1MHz", "Full_3MHz", "Full_5MHz", ...
                       "Cropped_1MHz", "Cropped_3MHz", "Cropped_5MHz"]
        RemoveOutlierThres = 15
    end

end
