classdef CameraManager < BaseObject
    %CAMERAMANAGER Manage multiple cameras

    properties (SetAccess = immutable)
        Andor19330 (1, 1) Camera
        Andor19331 (1, 1) Camera
        Zelux (1, 1) Camera
    end

    methods
        % When initiating in test mode, it creates cameras handle using 
        % 'Camera' class. When not in test mode, it creates actual cameras.
        function obj = CameraManager(options)
            arguments
                options.Andor19330 = AndorCameraConfig()
                options.Andor19331 = AndorCameraConfig()
                options.Zelux = ZeluxCameraConfig()
                options.test_mode = false
            end
            if options.test_mode
                obj.Andor19330 = Camera("Andor19330", options.Andor19330);
                obj.Andor19331 = Camera("Andor19331", options.Andor19331);
                obj.Zelux = Camera("Zelux", options.Zelux);
            else
                obj.Andor19330 = AndorCamera(19330, options.Andor19330);
                obj.Andor19331 = AndorCamera(19331, options.Andor19331);
                obj.Zelux = ZeluxCamera(0, options.Zelux);
            end
        end
        
        % Initialize selected cameras
        function init(obj, cameras)
            arguments
                obj
                cameras = obj.VisibleProp
            end
            for camera = cameras
                obj.(camera).init()
            end
        end
    
        % Configure cameras with a structure (similar to Data)
        function config(obj, data)
            for camera = obj.VisibleProp
                if (isfield(data, camera) || isprop(data, camera)) && isfield(data.(camera), "Config")
                    obj.(camera).config(data.(camera).Config)
                else
                    obj.warn("Unable to configure camera [%s], not existing in data.", camera)
                end
            end
        end
        
        % Abort acquisitions in selected cameras
        function abortAcquisition(obj, cameras)
            arguments
                obj
                cameras = obj.VisibleProp
            end
            for camera = cameras
                obj.(camera).abortAcquisition()
            end
        end
    end

    methods (Static)
        function obj = struct2obj(data, options)
            arguments
                data
                options.test_mode = true
            end
            args = {'test_mode', options.test_mode};
            if isfield(data, 'Andor19330')
                args = [args, {'Andor19330', AndorCameraConfig.struct2obj(data.Andor19330.Config)}];
            end
            if isfield(data, 'Andor19331')
                args = [args, {'Andor19331', AndorCameraConfig.struct2obj(data.Andor19331.Config)}];
            end
            if isfield(data, 'Zelux')
                args = [args, {'Zelux', ZeluxCameraConfig.struct2obj(data.Zelux.Config)}];
            end
            obj = CameraManager(args{:});
            obj.info("Object created from structure.")
        end
    end

end
