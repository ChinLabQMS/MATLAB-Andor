classdef AnalysisRegistry < BaseObject

    properties
        OutputVars
        OutputData
        FuncName
    end
    
    methods
        function obj = AnalysisRegistry(out_vars, out_data, func)
            arguments
                out_vars (1, :) string = string.empty
                out_data (1, :) string = string.empty
                func (1, 1) string = "NotImplemented"
            end
            obj.OutputVars = out_vars;
            obj.OutputData = out_data;
            obj.FuncName = func;
        end
    end

    enumeration
        FitCenter (["XCenter", "YCenter", "XWidth", "YWidth"], [], "fitCenter")
        FitGauss  (["GaussX", "GaussY", "GaussXWid", "GaussYWid"], [], "fitGauss")
        CalibLatR (["LatX", "LatY"], [], "calibLatR")
    end

end
