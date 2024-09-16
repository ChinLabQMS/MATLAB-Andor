classdef Acquisitor < handle

    properties (SetAccess = protected)
        CurrentIndex = 0
        AcquisitionConfig
        Cameras = struct('Andor19330', AndorCamera(19330), ...
                         'Andor19331', AndorCamera(19331), ...
                         'Zelux', ZeluxCamera(0))
        Data = nan
    end

    properties (Dependent, Hidden)
        CurrentLabel
    end
    
    methods
        function obj = Acquisitor(config)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
            end
            obj.AcquisitionConfig = config;
        end

        function init(obj)
            % Initialize active cameras and initialize Data storage
            active_cameras = obj.AcquisitionConfig.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                obj.Cameras.(camera).init();
            end
            obj.initData();
            fprintf("%s: Acquisitor initialized.\n", obj.CurrentLabel)
        end

        function close(obj)
            % Close all cameras
            all_cameras = fieldnames(obj.Cameras);
            for i = 1:length(all_cameras)
                camera = all_cameras{i};
                obj.Cameras.(camera).close();
            end
        end

        function config(obj, name, value)
            arguments
                obj
            end
            arguments (Repeating)
                name (1, 1) string
                value
            end
            arg_len = length(name);
            for i = 1:arg_len
                obj.AcquisitionConfig.(name{i}) = value{i};
            end
            obj.init()
        end

        function configCamera(obj, camera, varargin)
            obj.Cameras.(camera).config(varargin{:})
        end

        function initCamera(obj, camera)
            obj.Cameras.(camera).init()
        end

        function closeCamera(obj, camera)
            obj.Cameras.(camera).close()
        end

        function initData(obj)
            % Allocate empty storage for data and initialize the current index
            obj.CurrentIndex = 0;
            obj.Data = Dataset(obj.AcquisitionConfig, obj.Cameras);
        end
        
        function saveData(obj)
            if obj.CurrentIndex == 0
                error("%s: No data to save.", obj.CurrentLabel)
            end
            obj.Data.save()
        end

        function run(obj)
            obj.CurrentIndex = obj.CurrentIndex + 1;

            % TODO: change how the acquisition is imeplemented to enable mutiple images from the same camera     
            sequence_table = obj.AcquisitionConfig.ActiveSequence;
            sequence_length = height(sequence_table);
            new_images = cell(1, sequence_length);
            % Send "start acquisition" commands
            for i = 1:sequence_length
                camera_name = char(sequence_table.Camera(i));
                obj.Cameras.(camera_name).startAcquisition();
            end
            % Acquire images
            for i = 1:sequence_length
                camera = char(sequence_table.Camera(i));
                new_images{i} = obj.Cameras.(camera).acquire('refresh', obj.AcquisitionConfig.RefreshInterval, 'timeout', obj.AcquisitionConfig.Timeout);
            end
            
            obj.Data.add(obj.CurrentIndex, new_images);
            fprintf("%s: Acquisition completed.\n", obj.CurrentLabel)
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] %s (CurrentIndex: %d)', ...
                           datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss"), ...
                           class(obj), obj.CurrentIndex));
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.AcquisitionConfig)
        end

        function delete(obj)
            obj.close()
            delete@handle(obj)
            fprintf("%s: Acquisitor closed.\n", obj.CurrentLabel)
        end

    end

end
