classdef CombinedCalibrator < LatCalibrator & PSFCalibrator

    methods
        function obj = CombinedCalibrator(varargin)
            obj@LatCalibrator('reset_fields', false, 'init', false)
            obj@PSFCalibrator(varargin{:}, 'reset_fields', true, 'init', true)
        end

        function plotSignal(obj, index)
            plotSignal@LatCalibrator(obj, index)
            plotSignal@PSFCalibrator(obj, index)
        end

        function save(obj)
            save@LatCalibrator(obj)
            save@PSFCalibrator(obj)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@PSFCalibrator(obj, false)
            init@LatCalibrator(obj, true)
        end
    end

end
