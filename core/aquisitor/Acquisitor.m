classdef Acquisitor < handle

    properties (SetAccess = protected)
        CurrentIndex = 0
        Cameras = struct('Andor19330', AndorCamera(19330), ...
                         'Andor19331', AndorCamera(19331), ...
                         'Zelux', ZeluxCamera(0))
        AcquisitionConfig
        DataHandle
        NewImages
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
            obj.DataHandle = Dataset(obj.AcquisitionConfig, obj.Cameras);
        end
        
        function saveData(obj)
            if obj.CurrentIndex == 0
                error("%s: No data to save.", obj.CurrentLabel)
            end
            obj.DataHandle.save()
        end

        function runSingleAcquisition(obj)
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence_table = obj.AcquisitionConfig.ActiveSequence;
            new_images = cell(1, height(obj.AcquisitionConfig.ActiveAcquisition));
            index = 1;
            for i = 1:height(sequence_table)
                camera = obj.Cameras.(char(sequence_table.Camera(i)));
                type = char(sequence_table.Type(i));
                switch type
                    case 'Start'
                        camera.startAcquisition();
                    case 'Acquire'
                        new_images{index} = camera.acquire('refresh', obj.AcquisitionConfig.Refresh, 'timeout', obj.AcquisitionConfig.Timeout);
                        index = index + 1;
                    case 'Full'
                        camera.startAcquisition();
                        new_images{index} = camera.acquire('refresh', obj.AcquisitionConfig.Refresh, 'timeout', obj.AcquisitionConfig.Timeout);
                        index = index + 1;
                end
            end
            obj.NewImages = new_images;
            obj.DataHandle.update(obj.CurrentIndex, obj.NewImages)
            fprintf("%s: Acquisition completed.\n", obj.CurrentLabel)
        end

        function runAcquisitions(obj)
            for i = 1:obj.AcquisitionConfig.NumAcquisitions
                obj.runSingleAcquisition();
            end
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
