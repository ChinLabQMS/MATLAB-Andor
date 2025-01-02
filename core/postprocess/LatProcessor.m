classdef (Abstract) LatProcessor < BaseProcessor

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end

    methods
        function set.LatCalibFilePath(obj, path)
            obj.loadLatCalibFile(path)
            obj.LatCalibFilePath = path;
        end
    end

    methods (Access = protected, Hidden)
        function loadLatCalibFile(obj, path)
            if isempty(path)
                obj.LatCalib = [];
                obj.info("Pre-calibration is reset to empty structure.")
                return
            end
            obj.checkFilePath(path)
            obj.LatCalib = load(path);
            obj.info("Pre-calibration loaded from: '%s'.", path)
        end

        function init(obj)
            obj.assert(~isempty(obj.LatCalibFilePath), 'LatCalibFilePath is unset!')
        end
    end

end
