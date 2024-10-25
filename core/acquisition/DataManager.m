classdef DataManager < BaseStorage
    % DATAMANAGER Class for storing acquired data.

    methods
        function obj = DataManager(config, cameras)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager('test_mode', 1)
            end
            obj@BaseStorage("data", config, cameras)
        end
    end

    methods (Static)
        function [obj, acq_config, cameras] = struct2obj(data, acq_config, cameras, options)
            arguments
                data (1, 1) struct
                acq_config = []
                cameras = []
                options.test_mode (1, 1) logical = true
            end
            if isempty(acq_config)
                acq_config = AcquisitionConfig.struct2obj(data.AcquisitionConfig);
            else
                acq_config.configProp(data.AcquisitionConfig);
            end
            if isempty(cameras)
                cameras = CameraManager.struct2obj(data, "test_mode", options.test_mode);
            else
                for camera = cameras.prop()
                    cameras.(camera).config(data.(camera).Config);
                end
            end
            obj = DataManager(acq_config, cameras);
            for camera = acq_config.ActiveCameras
                obj.(camera) = data.(camera);
            end
            obj.CurrentIndex = acq_config.NumAcquisitions;
        end
    end

end
