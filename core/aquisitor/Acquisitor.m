classdef Acquisitor < handle

    properties (SetAccess = private)
        CurrentIndex = 0
        Config = AcquisitionConfig()
        Data (1, 1) Dataset
        Cameras (1, 1) struct = struct('Andor19330', nan, 'Andor19331', nan, 'Zelux', nan)
    end

    properties (Dependent)
        CurrentLabel
    end
    
    methods
        function obj = Acquisitor(varargin)
            % init cameras to get handles and live status
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
            obj.initActiveCameras()
            % TODO: init data
        end

        function initCameras(obj)
            camera_names = fieldnames(obj.Cameras);
            for i = 1:length(camera_names)
                camera_name = camera_names{i};
                camera_class = CameraLookup.(camera_name).CameraClass;
                camera_params = CameraLookup.(camera_name).InitParams;
                obj.Cameras.(camera_name) = feval(camera_class, camera_params{:});
            end
            obj.ActiveCameras = active_cameras;
        end

        function configCamera(obj, camera_name, vargin)
            if ~isfield(obj.ActiveCameras, camera_name)
                error("Camera %s is not active", camera_name);
            end
            obj.ActiveCameras.(camera_name).CameraObj.config(vargin{:});
        end

        function initCamera(obj, camera_name)
            obj.ActiveCameras.(camera_name).CameraObj.init();
        end

        function closeCamera(obj, camera_name)
            obj.ActiveCameras.(camera_name).CameraObj.close();
        end

        function runAcquisition(obj)            
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] Acquisitor', datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss")));
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.AcquisitorConfig)
        end

        function delete(obj)
            for camera_name = fieldnames(obj.ActiveCameras)'
                camera = camera_name{1};
                obj.ActiveCameras.(camera).CameraObj.delete();
            end
            delete@handle(obj)
            fprintf("%s: Acquisitor closed.\n", obj.CurrentLabel)
        end

    end
end
