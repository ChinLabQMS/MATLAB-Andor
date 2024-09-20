classdef Dataset < BaseConfig

    properties (SetAccess = protected, Transient)
        CurrentIndex (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
    end

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    properties (SetAccess = immutable)
        AcquisitionConfig
    end

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods
        function obj = Dataset(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras = Cameras.getStaticConfig()
            end
            obj.CurrentIndex = 0;
            obj.AcquisitionConfig = config;
            % Initialize Config for each active camera;
            sequence_table = config.ActiveAcquisition;
            active_cameras = config.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                if isfield(cameras, camera) || isprop(cameras, camera)
                    camera_config = cameras.(camera).Config;
                else
                    error("%s: Camera %s not found.", obj.CurrentLabel, camera)
                end
                obj.(camera) = struct();
                if isstruct(camera_config)
                    obj.(camera).Config = camera_config;
                else
                    obj.(camera).Config = camera_config.struct();
                end
                obj.(camera).Config.NumAcquisitions = config.NumAcquisitions;
                obj.(camera).Config.Note = struct();
                subsequence = sequence_table((sequence_table.Camera == camera), :);
                for j = 1:height(subsequence)
                    label = subsequence.Label(j);
                    obj.(camera).Config.Note.(label) = subsequence.Note(j);
                    if obj.(camera).Config.MaxPixelValue <= 65535
                        obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, obj.(camera).Config.YPixels, obj.(camera).Config.NumAcquisitions, "uint16");
                    else
                        error("%s: Unsupported pixel value range for camera %s.", obj.CurrentLabel, camera)
                    end    
                end
            end
            fprintf('%s: Data storage initialized for %d cameras, total memory is %g MB\n', ...
                obj.CurrentLabel, length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        function obj = add(obj, new_images)
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence_table = obj.AcquisitionConfig.ActiveAcquisition;
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                if obj.CurrentIndex > obj.AcquisitionConfig.NumAcquisitions
                    obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
                    obj.(camera).(label)(:,:,end) = new_images{i};
                else
                    obj.(camera).(label)(:,:,obj.CurrentIndex) = new_images{i};
                end
            end
            fprintf('%s: New images added to data in %.3f s\n', obj.CurrentLabel, toc(timer))
        end

        function s = struct(obj)
            s = struct@BaseConfig(obj, obj.AcquisitionConfig.ActiveCameras);
            s.AcquisitionConfig = obj.AcquisitionConfig.struct();
        end

        function save(obj, default_name)
            arguments
                obj
                default_name = 'data.mat'
            end
            if obj.CurrentIndex == 0
                error('%s: No data to save.', obj.CurrentLabel)
            end
            if obj.CurrentIndex < obj.AcquisitionConfig.NumAcquisitions
                warning('%s: Incomplete data, only %d of %d acquisitions.', obj.CurrentLabel, obj.CurrentIndex, obj.AcquisitionConfig.NumAcquisitions)
            end
            Data = obj.struct(); %#ok<NASGU>
            uisave('Data', default_name);
            fprintf('%s: %s saved.\n', obj.CurrentLabel, class(obj))
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
            s = struct(obj); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end

        function label = getStatusLabel(obj)
            label = sprintf(" (CurrentIndex: %d)", obj.CurrentIndex);
        end
    end

    methods (Static)
        function obj = struct2obj(s)
            config = AcquisitionConfig.struct2obj(s.AcquisitionConfig);
            obj = Dataset(config, s);
            obj.CurrentIndex = config.NumAcquisitions;
         end
    end

end
