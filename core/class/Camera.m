classdef (Abstract) Camera
    %CAMERA

    properties (Abstract, SetAccess = private)
        Initialized (1, 1) logical
        CameraConfig (1, 1) CameraConfig
    end

    methods (Abstract)
        init(obj)
        close(obj)
        config(obj)
        startAcquisition(obj)
        image = fetchImage(obj)
    end

end
