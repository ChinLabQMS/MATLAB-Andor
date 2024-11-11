classdef Replayer < BaseSequencer
    
    properties (SetAccess = {?BaseObject})
        DataPath = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj.DataPath = obj.DataPath;
        end

        function set.DataPath(obj, path)
            obj.DataPath = path;
            data = load(obj.DataPath, "Data").Data;
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
            obj.initSequence()
            obj.info2("Replay data loaded from '%s', sequence initialized.", obj.DataPath)
        end
    end

    methods (Access = protected, Hidden)
        function addData(~, ~)
        end

        function abortAtEnd(~)
        end
    end

end
