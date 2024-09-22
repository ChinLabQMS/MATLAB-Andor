classdef Dataset < BaseRunner

    properties (SetAccess = protected, Hidden)
        CurrentIndex (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
    end

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    properties (SetAccess = immutable, Hidden)
        Cameras
    end

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods
        function obj = Dataset(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) Cameras = Cameras()
            end
            obj@BaseRunner(config);
            obj.Cameras = cameras;
        end
        
        function init(obj)
            obj.CurrentIndex = 0;
            sequence_table = obj.Config.ActiveAcquisition;
            active_cameras = obj.Config.ActiveCameras;
            data = obj.Cameras.struct();
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                obj.(camera) = data.(camera);
                obj.(camera).Config.CameraName = camera;
                obj.(camera).Config.NumAcquisitions = obj.Config.NumAcquisitions;
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
                obj.CurrentLabel, length(obj.Config.ActiveCameras), obj.MemoryUsage)
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            obj.init()
        end

        function initCameras(obj)
            obj.Cameras.init(obj.Config.ActiveCameras)
        end

        function add(obj, new_images)
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence_table = obj.Config.ActiveAcquisition;
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                if obj.CurrentIndex > obj.Config.NumAcquisitions
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
            if options.check && (obj.CurrentIndex < obj.Config.NumAcquisitions)
                warning('%s: Incomplete data, only %d of %d acquisitions.', obj.CurrentLabel, obj.CurrentIndex, obj.Config.NumAcquisitions)
            end
            s = struct('AcquisitionConfig', obj.Config.struct());
            for camera = obj.Config.ActiveCameras
                s.(camera{1}) = obj.(camera{1});
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
            sequence_table = obj.Config.ActiveAcquisition;
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
        function obj = struct2obj(data)
            config = AcquisitionConfig.struct2obj(data.Config);
            obj = Dataset(config, data);
            obj.CurrentIndex = config.NumAcquisitions;
         end

        function obj = file2obj(filename)
            data = load(filename, 'Data');
            obj = Dataset.struct2obj(data);
        end
    end

end
