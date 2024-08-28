classdef (Abstract) Camera
    %CAMERA Generic class for camera object
    properties (Abstract, Constant)
        PhysicalSizeX (1, 1) double {mustBePositive, mustBeInteger}
        PhysicalSizeY (1, 1) double {mustBePositive, mustBeInteger}
    end

    properties (Abstract, SetAccess=private)
        ExternalTrigger (1, 1) logical
        Exposure (1, 1) double
        Initialized (1, 1) logical
    end

    methods (Abstract)
        init(obj)
        close(obj)
        acquireImage(obj)
    end
end
