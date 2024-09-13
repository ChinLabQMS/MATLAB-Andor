classdef Acquisitor < handle

    properties (SetAccess = private)
        CurrentIndex = 0
        Config = AcquisitionConfig()
        Cameras = struct('Andor19330', nan, 'Andor19331', nan, 'Zelux', nan)
        Data = nan
    end

    properties (Dependent)
        CurrentLabel
    end
    
    methods
        function obj = Acquisitor(varargin)
            obj.config(varargin{:})
            fprintf("%s: Acquisitor initialized.\n", obj.CurrentLabel)
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
                obj.Config.(name{i}) = value{i};
            end
            obj.initCameras()
            obj.initData()
        end

        function initCameras(obj)
            % init cameras to get handles and live status
            camera_names = fieldnames(obj.Cameras);
            active_cameras = string(unique(obj.Config.SequenceTable.Camera));
            for i = 1:length(camera_names)
                camera_name = camera_names{i};
                if isnan(obj.Cameras.(camera_name))
                    camera_class = CameraLookup.(camera_name).CameraClass;
                    camera_params = CameraLookup.(camera_name).InitParams;
                    obj.Cameras.(camera_name) = feval(camera_class, camera_params{:});
                    if ~ismember(camera_name, active_cameras)
                        obj.Cameras.(camera_name).close()
                    end
                elseif ismember(camera_name, active_cameras)
                    obj.Cameras.(camera_name).init()
                end
            end
        end

        function configCamera(obj, camera_name, vargin)
            obj.Cameras.(camera_name).config(vargin{:});
        end

        function initCamera(obj, camera_name)
            if ~obj.Cameras.(camera_name).Initialized
                obj.Cameras.(camera_name).init();
            end
        end

        function closeCamera(obj, camera_name)
            obj.Cameras.(camera_name).close();
        end

        function initData(obj)
            % Allocate empty storage for data and initialize the current index
            obj.CurrentIndex = 0;
            obj.Data = Dataset(obj.Config, obj.Cameras);
        end
        
        function saveData(obj)
            obj.Data.save()
        end

        function runAcquisition(obj)
            % TODO: update new_data with the data from the cameras
            new_data = nan;
            obj.Data.update(obj.CurrentIndex, new_data);
            obj.CurrentIndex = obj.CurrentIndex + 1;
            fprintf("%s: Acquisition %d/%d completed.\n", obj.CurrentLabel, obj.CurrentIndex, obj.Config.NumAcquisitions)
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] Acquisitor', datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss")));
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end

        function delete(obj)
            for camera_name = fieldnames(obj.Cameras)'
                camera = camera_name{1};
                obj.Cameras.(camera).delete();
            end
            delete@handle(obj)
            fprintf("%s: Acquisitor closed.\n", obj.CurrentLabel)
        end

    end
end
