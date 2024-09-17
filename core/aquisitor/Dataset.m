classdef Dataset < dynamicprops

    properties
        AcquisitionConfig
    end

    properties (Dependent, Hidden)
        CurrentLabel
        MemoryUsage
    end

    methods

        function obj = Dataset(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig
                cameras (1, 1) struct
            end
            obj.AcquisitionConfig = config;
            
            % Initialize Config for each active camera
            sequence_table = config.ActiveAcquisition;
            active_cameras = config.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                obj.addprop(camera);
                obj.(camera) = struct();
                obj.(camera).Config = struct(cameras.(camera).CameraConfig);
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
                obj.CurrentLabel, length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        function update(obj, index, new_data)
            if index > obj.AcquisitionConfig.NumAcquisitions
                insert_index = obj.AcquisitionConfig.NumAcquisitions;
                shift = true;
            else
                insert_index = index;
                shift = false;
            end
            sequence_table = obj.AcquisitionConfig.ActiveAcquisition;
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
            fields = fieldnames(obj);
            s = struct();
            for i = 1:length(fields)
                s.(fields{i}) = obj.(fields{i});
            end
        end

        function save(obj)
            Data = obj.struct(); %#ok<NASGU>
            uisave('Data', 'data.mat');
            fprintf('%s: Data saved as a structure.\n', obj.CurrentLabel)
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] %s', ...
                           datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                           class(obj)));
        end

        function usage = get.MemoryUsage(obj)
            s = struct(obj); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end

    end
end
