classdef Replayer < BaseSequencer & DataProcessor
    
    properties (SetAccess = {?BaseObject})
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj@DataProcessor()
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@DataProcessor(obj)
            obj.AcquisitionConfig.config(obj.Raw.AcquisitionConfig)
            obj.CameraManager.config(obj.Raw)
            obj.DataStorage.config(obj.Raw, "config_cameras", false, "config_acq", false)
            obj.initSequence()
            obj.Raw = [];
            obj.Signal = [];
            obj.Leakage = [];
            obj.Noise = [];
            obj.info2("Replay data loaded from '%s', sequence initialized.", obj.DataPath)
        end

        function start(~, ~, ~, varargin)
        end
        
        function acquire(obj, camera, label, varargin)
            obj.Live.Raw.(camera).(label) = obj.DataStorage.(camera).(label)(:, :, obj.CurrentIndex);
        end

        function addData(~, ~)
        end

        function abortAtEnd(~)
        end
    end

end
