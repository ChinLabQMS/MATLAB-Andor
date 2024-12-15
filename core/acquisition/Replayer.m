classdef Replayer < BaseSequencer & BaseProcessor
    
    properties (SetAccess = {?BaseObject})
        DataPath = "calibration/example_data/20241126_normal_upper_not_on_focus.mat"
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj@BaseProcessor()
        end

        function set.DataPath(obj, path)
            obj.checkFilePath(path, 'DataPath')
            data = load(path, "Data").Data;
            obj.DataPath = path;
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
            obj.initSequence()
            obj.info2("Replay data loaded from '%s', sequence initialized.", obj.DataPath)
        end
    end

    methods (Access = protected, Hidden)
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
