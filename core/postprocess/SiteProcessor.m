classdef SiteProcessor < CombinedProcessor

    properties (Constant)
        SiteCounterList = ["Andor19330", "Andor19331"]
        SiteGridParams = {}
    end

    properties (SetAccess = protected)
        SiteCounters
        SiteGridHandle
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@CombinedProcessor(obj)
            obj.SiteGridHandle = SiteGrid(obj.SiteGridParams{:});
            for camera = obj.SiteCounterList
                obj.SiteCounters.(camera) = SiteCounter(camera, obj.LatCalib.(camera), obj.PSFCalib.(camera), obj.SiteGridHandle);
            end
        end
    end
end
