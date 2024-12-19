classdef (Abstract) PSFProcessor < BaseProcessor

    properties (SetAccess = {?BaseObject})
        PSFCalibFilePath = "calibration/PSFCalib.mat"
    end
    
    properties (SetAccess = protected)
        PSFCalib
    end

    methods
        function set.PSFCalibFilePath(obj, path)
            obj.loadPSFCalib(path)
            obj.PSFCalibFilePath = path;
        end
    end

    methods (Access = protected, Hidden)
        function loadPSFCalib(obj, path)
           obj.checkFilePath(path, 'PSFCalibFilePath')
           obj.PSFCalib = load(path);
           obj.info("PSFCalib is loaded from '%s'", path)
        end

        function init(obj)
            obj.assert(~isempty(obj.PSFCalibFilePath), 'PSFCalibFilePath is unset!')
        end
    end

end
