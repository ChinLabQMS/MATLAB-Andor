classdef LatticeConfig < BaseObject

    properties (SetAccess = {?BaseRunner})
        CalibR_BinarizeThres = 0.5
        CalibV_RFit = 7
        CalibV_WarnLatNormThres = 0.001
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibV_PlotFFTPeaks = false
    end
    
end
