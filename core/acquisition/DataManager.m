classdef DataManager < BaseStorage
    % DATAMANAGER Class for storing acquired data.

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    properties (SetAccess = immutable, Hidden)
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
            for camera = obj.getPropList()
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
        function [data, config, cameras] = struct2obj(data_struct, options)
            arguments
                data_struct (1, 1) struct
                options.test_mode (1, 1) logical = true
            end
            config = AcquisitionConfig.struct2obj(data_struct.AcquisitionConfig);
            cameras = CameraManager.struct2obj(data_struct, "test_mode", options.test_mode);
            data = DataManager(config, cameras);
            for camera = config.ActiveCameras
                data.(camera) = data_struct.(camera);
            end
            data.CurrentIndex = config.NumAcquisitions;
            data.info("Loaded from structure.")
        end
    end

end
