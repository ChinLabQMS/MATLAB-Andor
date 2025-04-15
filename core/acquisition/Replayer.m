classdef Replayer < BaseSequencer & DataProcessor
    
    properties (Constant)
        DefaultDataPath = "data/2025/04 April/20250411/dense_calibration.mat"
    end

    properties (SetAccess = {?BaseObject})
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj@DataProcessor('DataPath', Replayer.DefaultDataPath)
        end

        function initSequence2(obj)
            obj.initSequence()
            obj.info2("Sequence is initialized.")
        end
    end

    methods (Access = protected, Hidden)
        % Override the load data function in DataProcessor
        function loadData(obj, path)
            loadData@DataProcessor(obj, path)
            obj.AcquisitionConfig.config(obj.Raw.AcquisitionConfig)
            obj.CameraManager.config(obj.Raw)
            obj.DataStorage.config(obj.Raw, "config_cameras", false, "config_acq", false)
            obj.initSequence()
            obj.info("Data loaded from: '%s', sequence initialized.", path)
        end
        
        % Override the start acquisition command, do not operate cameras
        function start(~, ~, ~, varargin)
        end
        
        % Override the acquire image command, do not operate cameras
        function acquire(obj, camera, label, varargin)
            obj.Live.Raw.(camera).(label) = obj.DataStorage.(camera).(label)(:, :, obj.CurrentIndex);
        end
        
        % Override the move command, do not operate the picomotors
        function move(~, ~, ~, varargin)
        end
        
        % Override the add data to storage command
        function addData(~, ~)
        end
        
        % Override the abort camera at the end command
        function abortAtEnd(~)
        end
    end

end
