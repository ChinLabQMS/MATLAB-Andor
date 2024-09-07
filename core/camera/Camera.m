classdef (Abstract) Camera < handle
    %CAMERA

    properties (Abstract, SetAccess = private)
        Initialized (1, 1) logical
        CameraLabel (1, 1) string
        CameraConfig (1, 1) CameraConfig
    end

    properties (Abstract, Dependent)
        CurrentLabel (1, 1) string
    end

    methods (Abstract)
        init(obj)
        close(obj)
        config(obj)
        startAcquisition(obj)
        abortAcquisition(obj)
        image = getImage(obj)
    end

    methods
        function disp(obj)
            disp@handle(obj)
            disp(obj.CameraConfig)
        end

        function delete(obj)
            obj.close();
            delete@handle(obj)
        end
    end

end
