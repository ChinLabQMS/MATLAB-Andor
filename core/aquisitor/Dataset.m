classdef Dataset < BaseObject & dynamicprops

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods

        function obj = Dataset(config)
            arguments
                config (1, 1) AcquisitorConfig
            end
            obj@BaseObject("", config)
        end

        function init(obj, cameras)
            config = obj.Config;
            % Initialize Config for each active camera
            sequence_table = config.ActiveAcquisition;
            active_cameras = config.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                camera_handle = cameras.(camera);
                obj.addprop(camera);
                obj.(camera) = struct();
                obj.(camera).Config = camera_handle.Config.struct();
                obj.(camera).Config.NumAcquisitions = config.NumAcquisitions;
                obj.(camera).Config.Note = struct();
                subsequence = sequence_table((sequence_table.Camera == camera), :);
                for j = 1:height(subsequence)
                    label = subsequence.Label(j);
                    obj.(camera).Config.Note.(label) = subsequence.Note(j);
                    if obj.(camera).Config.MaxPixelValue <= 65535
                        obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, obj.(camera).Config.YPixels, obj.(camera).Config.NumAcquisitions, "uint16");
                    else
                        error("%s: Unsupported pixel value range.", obj.CurrentLabel)
                    end    
                end
            end
            fprintf('%s: Data storage initialized for %d cameras, total memory is %g MB\n', ...
                obj.CurrentLabel, length(obj.Config.ActiveCameras), obj.MemoryUsage)
        end

        function update(obj, index, new_data)
            if index > obj.Config.NumAcquisitions
                insert_index = obj.Config.NumAcquisitions;
                shift = true;
            else
                insert_index = index;
                shift = false;
            end
            sequence_table = obj.Config.ActiveAcquisition;
            for i = 1:height(sequence_table)
                camera = char(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                if shift
                    obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
                end
                obj.(camera).(label)(:,:,insert_index) = new_data{i};
            end
        end

        function s = struct(obj)
            active_cameras = obj.Config.ActiveCameras;
            s = struct();
            s.AcquisitionConfig = obj.Config.struct();
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                s.(camera) = obj.(camera);
            end
        end

        function save(obj)
            Data = obj.struct(); %#ok<NASGU>
            uisave('Data', 'data.mat');
            fprintf('%s: %s saved as a structure.\n', obj.CurrentLabel, class(obj))
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
            s = struct(obj); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end

    end
end
