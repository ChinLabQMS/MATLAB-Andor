classdef Acquisitor < BaseObject

    properties (SetAccess = protected)
        CurrentIndex = 0
        Cameras = struct('Andor19330', AndorCamera(19330), ...
                         'Andor19331', AndorCamera(19331), ...
                         'Zelux', ZeluxCamera(0))
        DataHandle
        NewImages
    end
    
    methods
        function obj = Acquisitor(config)
            arguments
                config (1, 1) AcquisitorConfig = AcquisitorConfig()
            end
            obj = obj@BaseObject("", config);
            obj.Initialized = true;
        end

        function init(obj)
            % Initialize active cameras and initialize Data storage
            active_cameras = obj.Config.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                obj.Cameras.(camera).init();
            end
            obj.initData();
            fprintf("%s: %s initialized.\n", obj.CurrentLabel, class(obj))
        end

        function close(obj)
            % Close all cameras
            all_cameras = fieldnames(obj.Cameras);
            for i = 1:length(all_cameras)
                camera = all_cameras{i};
                obj.Cameras.(camera).close();
            end
            fprintf("%s: %s closed.\n", obj.CurrentLabel, class(obj))
        end

        function config(obj, varargin)
            config@BaseObject(obj, varargin{:})
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

        function configCameras(obj, varargin)
            % Configure all active cameras
            active_cameras = obj.Config.ActiveCameras;
            for i = 1:length(active_cameras)
                camera = active_cameras{i};
                obj.configCamera(camera, varargin{:})
            end
        end

        function initData(obj)
            % Allocate empty storage for data and initialize the current index
            obj.CurrentIndex = 0;
            obj.DataHandle = Dataset(obj.Config);
            obj.DataHandle.init(obj.Cameras)
        end
        
        function saveData(obj)
            if obj.CurrentIndex == 0
                error("%s: No data to save.", obj.CurrentLabel)
            end
            obj.DataHandle.save()
        end

        function acquire(obj)
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            sequence_table = obj.Config.ActiveSequence;
            new_images = cell(1, height(obj.Config.ActiveAcquisition));
            index = 1;
            start_time = toc(timer);
            for i = 1:height(sequence_table)
                camera = obj.Cameras.(char(sequence_table.Camera(i)));
                type = char(sequence_table.Type(i));
                switch type
                    case 'Start'
                        camera.startAcquisition();
                    case 'Acquire'
                        new_images{index} = camera.acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                        index = index + 1;
                    case 'Full'
                        camera.startAcquisition();
                        new_images{index} = camera.acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                        index = index + 1;
                end
            end
            acquisition_time = toc(timer) - start_time;
            obj.NewImages = new_images;
            obj.DataHandle.update(obj.CurrentIndex, obj.NewImages)
            cycle_time = toc(timer);
            storage_time = cycle_time - acquisition_time;
            fprintf("%s: Acquisition %d completed, cycle time: %.3f s, acquisition time: %.3f s, storage time: %.3f s\n", ...
                obj.CurrentLabel, obj.CurrentIndex, cycle_time, acquisition_time, storage_time)
        end

        function run(obj)
            obj.init()
            for i = 1:obj.Config.NumAcquisitions
                obj.acquire();
            end
            fprintf("%s: Acquisition completed.\n", obj.CurrentLabel)
        end

        function label = getCurrentLabel(obj)
            label = getCurrentLabel@BaseObject(obj) + sprintf("(CurrentIndex = %d)", obj.CurrentIndex);
        end

    end

end
