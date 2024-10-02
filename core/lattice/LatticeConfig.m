classdef LatticeConfig < BaseObject

    properties (SetAccess = {?BaseObject})
        CalibR_BinarizeThres = 20
        CalibR_OutlierThres = 1000
        CalibV_RFit = 7
        CalibV_WarnLatNormThres = 0.01
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibV_PlotFFTPeaks = false
    end

    methods (Static)
        function obj = struct2obj(s)
            obj = BaseObject.struct2obj(s, LatticeConfig());
        end

        function obj = file2obj(filename)
            obj = BaseObject.file2obj(filename, LatticeConfig());
        end
    end

end
