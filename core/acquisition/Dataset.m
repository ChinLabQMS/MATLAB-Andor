classdef Dataset < BaseStorage

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    properties (SetAccess = immutable, Hidden)
        CameraManager
    end

    methods
        function obj = Dataset(config, cameras)
            arguments
                config = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager()
            end
            obj@BaseStorage(config)
            obj.CameraManager = cameras;
        end
        
        function init(obj)
            obj.CurrentIndex = 0;
            sequence = obj.AcquisitionConfig.ActiveSequence;
            for camera = obj.AcquisitionConfig.ActiveCameras
                obj.(camera).Config = obj.CameraManager.(camera).Config.struct();
                obj.(camera).Config.CameraName = camera;
                obj.(camera).Config.NumAcquisitions = obj.AcquisitionConfig.NumAcquisitions;
                camera_seq = sequence((sequence.Camera == camera), :);
                for j = 1:height(camera_seq)
                    label = camera_seq.Label(j);
                    if camera_seq.Type(j) == "Analysis"
                        obj.(camera).Config.AnalysisNote.(label) = camera_seq.Note(j);
                    else
                        obj.(camera).Config.AcquisitionNote.(label) = camera_seq.Note(j);
                        if obj.(camera).Config.MaxPixelValue <= 65535
                            obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, obj.(camera).Config.YPixels, obj.(camera).Config.NumAcquisitions, "uint16");
                        else
                            error("%s: Unsupported pixel value range for camera %s.", obj.CurrentLabel, camera)
                        end
                    end
                end
            end
            fprintf("%s: %s storage initialized for %d cameras, total memory is %g MB.\n", ...
                obj.CurrentLabel, class(obj), length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        function add(obj, new_images, options)
            arguments
                obj
                new_images (1, 1) struct
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
                    obj.(camera).(label)(:,:,end) = new_images.(camera).(label);
                else
                    obj.(camera).(label)(:,:,obj.CurrentIndex) = new_images.(camera).(label);
                end
            end
            if options.verbose
                fprintf('%s: New images added to %s in %.3f s\n', obj.CurrentLabel, class(obj), toc(timer))
            end
        end

        function plot(obj, options)
            arguments
                obj
                options.sample_index = 1
            end
            sequence = obj.AcquisitionConfig.ActiveAcquisition;
            for i = 1:height(sequence)
                camera = char(sequence.Camera(i));
                label = sequence.Label(i);
                figure()
                imagesc(obj.(camera).(label)(:,:,options.sample_index))
                axis image
                colorbar eastoutside
                title(sprintf('Sample %d (%s: %s)', options.sample_index, camera, label))
            end
            for i = 1:height(sequence)
                camera = char(sequence.Camera(i));
                label = sequence.Label(i);
                figure()
                imagesc(mean(obj.(camera).(label), 3))
                axis image
                colorbar eastoutside
                title(sprintf('Mean (%s: %s)', camera, label))
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
            data = Dataset(config, cameras);
            for camera = config.ActiveCameras
                data.(camera) = data_struct.(camera);
            end
            data.CurrentIndex = config.NumAcquisitions;
            fprintf("%s: %s loaded from structure.\n", obj.CurrentLabel, class(obj))
        end

        function obj = file2obj(filename, varargin)
            if isfile(filename)
                s = load(filename, 'Data');
                obj = Dataset.struct2obj(s, varargin{:});
            else
                error("File %s does not exist.", filename)
            end
        end
    end

end
