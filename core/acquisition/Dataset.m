classdef Dataset < BaseObject

    properties (SetAccess = protected, Hidden)
        CurrentIndex (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
    end

    properties (SetAccess = protected)
        AcquisitionConfig
        Andor19330
        Andor19331
        Zelux
    end

    properties (SetAccess = immutable, Hidden)
        CameraManager
    end

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods
        function obj = Dataset(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager()
            end
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
        end
        
        function init(obj)
            obj.CurrentIndex = 0;
            sequence_table = obj.AcquisitionConfig.ActiveAcquisition;
            data = obj.CameraManager.struct();
            for camera = obj.AcquisitionConfig.ActiveCameras
                obj.(camera) = data.(camera);
                obj.(camera).Config.CameraName = camera;
                obj.(camera).Config.NumAcquisitions = obj.AcquisitionConfig.NumAcquisitions;
                obj.(camera).Config.Note = struct();
                camera_seq = sequence_table((sequence_table.Camera == camera), :);
                for j = 1:height(camera_seq)
                    label = camera_seq.Label(j);
                    obj.(camera).Config.Note.(label) = camera_seq.Note(j);
                    if obj.(camera).Config.MaxPixelValue <= 65535
                        obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, obj.(camera).Config.YPixels, obj.(camera).Config.NumAcquisitions, "uint16");
                    else
                        error("%s: Unsupported pixel value range for camera %s.", obj.CurrentLabel, camera)
                    end
                end
            end
            fprintf("%s: Data storage initialized for %d cameras, total memory is %g MB\n", ...
                obj.CurrentLabel, length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        function add(obj, new_images)
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence_table = obj.AcquisitionConfig.ActiveAcquisition;
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                if obj.CurrentIndex > obj.AcquisitionConfig.NumAcquisitions
                    obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
                    obj.(camera).(label)(:,:,end) = new_images.(camera).(label);
                else
                    obj.(camera).(label)(:,:,obj.CurrentIndex) = new_images.(camera).(label);
                end
            end
            fprintf('%s: New images added to data in %.3f s\n', obj.CurrentLabel, toc(timer))
        end

        function s = struct(obj, options)
            arguments
                obj
                options.check = true
            end
            if options.check && (obj.CurrentIndex < obj.AcquisitionConfig.NumAcquisitions)
                warning('%s: Incomplete data, only %d of %d acquisitions.', obj.CurrentLabel, obj.CurrentIndex, obj.AcquisitionConfig.NumAcquisitions)
            end
            s = struct('AcquisitionConfig', obj.AcquisitionConfig.struct());
            for camera = obj.AcquisitionConfig.ActiveCameras
                s.(camera) = obj.(camera);
            end
        end

        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = class(obj) + ".mat"
            end
            save@BaseRunner(obj, filename, "struct_export", true)
        end

        function plot(obj, options)
            arguments
                obj
                options.sample_index = 1
            end
            sequence_table = obj.AcquisitionConfig.ActiveAcquisition;
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                figure()
                imagesc(obj.(camera).(label)(:,:,options.sample_index))
                axis image
                colorbar eastoutside
                title(sprintf('Sample %d (%s: %s)', options.sample_index, camera, label))
            end
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                figure()
                imagesc(mean(obj.(camera).(label), 3))
                axis image
                colorbar eastoutside
                title(sprintf('Mean (%s: %s)', camera, label))
            end
        end

        function usage = get.MemoryUsage(obj)
            s = struct(obj, "check", false); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end

        function label = getStatusLabel(obj)
            label = sprintf(" (CurrentIndex: %d)", obj.CurrentIndex);
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
