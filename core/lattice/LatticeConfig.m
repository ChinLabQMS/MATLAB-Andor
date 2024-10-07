classdef LatticeConfig < BaseObject

    properties (SetAccess = {?BaseRunner})
        CalibR_BinarizeThres = 20
        CalibR_OutlierThres = 1000
        CalibV_RFit = 7
        CalibV_WarnLatNormThres = 0.01
        CalibV_WarnRSquared = 0.5
        CalibV_PlotDiagnostic = false
        CalibV_PlotFFTPeaks = false
    end
    
end
