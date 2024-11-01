classdef Replayer < BaseSequencer & BaseProcessor

    properties (SetAccess = {?BaseObject})
        DataPath = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        CurrentIndex
    end

    methods
        function obj = Replayer(varargin)
            obj@BaseSequencer(varargin{:})
            obj@BaseProcessor()
        end

        function set.DataPath(obj, path)
            obj.DataPath = path;
            data = load(obj.DataPath, "Data").Data;
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
            obj.StatStorage.init()
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Replay data loaded and sequence initialized.")
        end
    end

    methods (Access = protected, Hidden)
        function init(~)
        end

        function startAcquisition(~, ~, varargin)
        end
        
        function acquireImage(obj, info, varargin)
            obj.Live.Raw.(info.camera).(info.label) = ...
                obj.DataStorage.(info.camera).(info.label)(:, :, obj.CurrentIndex);
        end

        function addData(~, ~)
        end

        function abortAtEnd(~)
        end
    end

end
