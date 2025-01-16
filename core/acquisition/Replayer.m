classdef Replayer < BaseSequencer & DataProcessor
    
    properties (Constant)
        DefaultDataPath = "data/2024/12 December/20241220/DMD=1.0in_spot_r=2_spacing=100.mat"
    end

    properties (SetAccess = {?BaseObject})
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj@DataProcessor('DataPath', Replayer.DefaultDataPath)
        end
    end

    methods (Access = protected, Hidden)
        function loadData(obj, path)
            loadData@DataProcessor(obj, path)
            obj.AcquisitionConfig.config(obj.Raw.AcquisitionConfig)
            obj.CameraManager.config(obj.Raw)
            obj.DataStorage.config(obj.Raw, "config_cameras", false, "config_acq", false)
            obj.initSequence()
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
