classdef SiteProcessor < CombinedProcessor

    properties (SetAccess = {?BaseObject})
        SiteCounterList = ["Andor19330", "Andor19331"]
        SiteGridParams = {'SiteFormat', 'Hex', 'HexRadius', 12; 
                          'SiteFormat', 'Hex', 'HexRadius', 12}
    end

    properties (SetAccess = protected)
        SiteCounters
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@CombinedProcessor(obj)
            for i = 1: length(obj.SiteCounterList)
                camera = obj.SiteCounterList(i);
                obj.SiteCounters.(camera) = SiteCounter(camera, obj.LatCalib.(camera), obj.PSFCalib.(camera));
                grid_params = obj.SiteGridParams(i, :);
                obj.SiteCounters.(camera).configGrid(grid_params{:})
            end
            obj.info("SiteProcessor is initialized with loaded LatCalib and PSFCalib.")
        end
    end
end
