classdef Acquisitor < BaseSequencer

    methods
        % Initialize acquisition
        function init(obj)
            fprintf('-------------------------------Start initialization------------------------------\n')
            obj.CameraManager.init(obj.AcquisitionConfig.ActiveDevices)
            obj.DataStorage.init()
            obj.initSequence()
            obj.info2("Sequence initialized.")
            fprintf('-------------------------------Finish initialization------------------------------\n\n')
        end
        
        % Configure the acquisition to a data
        function config(obj, data)
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
        end
    end

end
