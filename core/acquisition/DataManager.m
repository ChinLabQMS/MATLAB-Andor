classdef DataManager < BaseStorage
    % DATAMANAGER Class for storing acquired data.

    properties (SetAccess = immutable)
        CameraManager
    end

    methods
        function obj = DataManager(config, cameras)
            arguments
                config = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager('test_mode', 1)
            end
            obj@BaseStorage(config)
            obj.CameraManager = cameras;
        end
        
        % Initialize the storage
        function init(obj)
            obj.CurrentIndex = 0;
            sequence = obj.AcquisitionConfig.ActiveSequence;
            num_acq = obj.AcquisitionConfig.NumAcquisitions;
            for camera = obj.prop()
                if ~ismember(camera, obj.AcquisitionConfig.ActiveCameras)
                    obj.(camera) = [];
                    continue
                end
                % Record camera config
                obj.(camera).Config = obj.CameraManager.(camera).Config.struct();
                % Record some additional information to the camera config
                obj.(camera).Config.CameraName = camera;
                obj.(camera).Config.NumAcquisitions = obj.AcquisitionConfig.NumAcquisitions;
                camera_seq = sequence((sequence.Camera == camera), :);
                for j = 1:height(camera_seq)
                    label = camera_seq.Label(j);
                    if camera_seq.Type(j) == "Analysis"
                        obj.(camera).Config.AnalysisNote.(label) = camera_seq.Note(j);
                    elseif camera_seq.Type(j) == "Acquire" || camera_seq.Type(j) == "Start+Acquire"
                        obj.(camera).Config.AcquisitionNote.(label) = camera_seq.Note(j);
                        if obj.(camera).Config.MaxPixelValue <= 65535
                            obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, obj.(camera).Config.YPixels, num_acq, "uint16");
                        else
                            obj.error("Unsupported pixel value range for camera %s.", camera)
                        end
                    end
                end
            end
            obj.info("Storage initialized for %d cameras, total memory is %g MB.", ...
                     length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        % Add new images to the storage
        function add(obj, raw_images, options)
            arguments
                obj
                raw_images (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence = obj.AcquisitionConfig.ActiveAcquisition;
            for i = 1:height(sequence)
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                if obj.CurrentIndex > size(obj.(camera).(label), 3)
                    obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
                    obj.(camera).(label)(:,:,end) = raw_images.(camera).(label);
                else
                    obj.(camera).(label)(:,:,obj.CurrentIndex) = raw_images.(camera).(label);
                end
            end
            if options.verbose
                obj.info('Raw images added to index %d in %.3f s', obj.CurrentIndex, toc(timer))
            end
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
