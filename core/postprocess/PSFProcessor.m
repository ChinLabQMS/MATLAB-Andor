classdef (Abstract) PSFProcessor < BaseProcessor

    properties (SetAccess = {?BaseObject})
        PSFCalibFilePath = "calibration/PSFCalib.mat"
    end
    
    properties (SetAccess = protected)
        PSFCalib
    end

    methods
        function set.PSFCalibFilePath(obj, path)
            obj.loadPSFCalibFile(path)
            obj.PSFCalibFilePath = path;
        end
    end

    methods (Access = protected, Hidden)
        function loadPSFCalibFile(obj, path)
           if isempty(path)
                obj.PSFCalib = [];
                obj.info("PSF calibration is reset to empty structure.")
                return
           end
           obj.checkFilePath(path, 'PSFCalibFilePath')
           obj.PSFCalib = load(path);
           obj.info("PSFCalib loaded from '%s'", path)
        end

        function init(obj)
            obj.assert(~isempty(obj.PSFCalibFilePath), 'PSFCalibFilePath is unset!')
        end
    end

end
