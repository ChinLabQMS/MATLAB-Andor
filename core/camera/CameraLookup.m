classdef CameraLookup
    %CAMERALOOKUP
    
    properties
        Andor19330 = struct(CameraClass="AndorCamera", InitParams={19330})
        Andor19331 = struct(CameraClass="AndorCamera", InitParams={19331})
        Zelux = struct(CameraClass="ZeluxCamera", InitParams={0})
    end
    
end