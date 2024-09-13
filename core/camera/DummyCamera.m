classdef DummyCamera < Camera
    %DUMMYCAMERA Test camera class for debugging

    properties (SetAccess = private)
        Initialized = false
        CameraConfig = ZeluxCameraConfig()
    end

    properties (Dependent)
        CurrentLabel
    end

    methods
        function init(obj)
            obj.Initialized = true;
            init@Camera(obj)
        end

        function close(obj)
            obj.Initialized = false;
            close@Camera(obj)
        end

        function startAcquisition(obj)
        end

        function abortAcquisition(obj)
        end

        function image = getImage(obj)
            image = randi(obj.CameraConfig.MaxPixelValue, obj.CameraConfig.XPixels, obj.CameraConfig.YPixels);
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] DummyCamera', datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss")));
        end
    end

end
