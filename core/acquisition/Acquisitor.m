classdef Acquisitor < BaseSequencer

    methods
        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.AcquisitionConfig.ActiveCameras)
            obj.DataStorage.init()
            obj.StatStorage.init()
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.Timer = tic;
            obj.Live = LiveData();
            obj.initSequence()
            obj.info2("Sequence initialized.")
        end
        
        % Configure the acquisition to a data
        function config(obj, data)
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
        end
    end

end
