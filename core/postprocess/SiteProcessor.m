classdef SiteProcessor < CombinedProcessor

    properties (Constant)
        SiteCounterList = ["Andor19330", "Andor19331"]
        SiteGridParams = {'SiteFormat', 'Hex', 'HexRadius', 12}
    end

    properties (SetAccess = protected)
        SiteCounters
        SiteGridShared
    end

    methods
        function configGrid(obj, varargin)
            obj.SiteGridShared.config(varargin{:})
            for camera = obj.SiteCounterList
                obj.SiteCounters.(camera).updateDeconvWeight()
            end
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@CombinedProcessor(obj)
            obj.SiteGridShared = SiteGrid(obj.SiteGridParams{:});
            for camera = obj.SiteCounterList
                obj.SiteCounters.(camera) = SiteCounter(camera, obj.LatCalib.(camera), obj.PSFCalib.(camera), obj.SiteGridShared);
            end
        end
    end
end
