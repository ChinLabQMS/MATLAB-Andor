classdef (Abstract) Camera
    %CAMERA Generic class for camera object
    properties (Abstract, SetAccess=private)
        Initialized (1, 1) logical
        ExternalTrigger (1, 1) logical
        Exposure (1, 1) double
        ImageSizeX (1, 1) double {mustBePositive, mustBeInteger}
        ImageSizeY (1, 1) double {mustBePositive, mustBeInteger}
    end
    methods (Abstract)
        init(obj)
        close(obj)
    end
end
