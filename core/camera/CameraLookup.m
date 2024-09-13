classdef CameraLookup
    %CAMERALOOKUP
    
    properties
        CameraClass
        InitParams
    end

    methods
        function obj = CameraLookup(class_name, init_params)
            obj.CameraClass = class_name;
            obj.InitParams = init_params;
        end
    end

    enumeration
        Andor19330  ('AndorCamera', {19330})
        Andor19331  ('AndorCamera', {19331})
        Zelux       ('ZeluxCamera', {0})
    end
    
end