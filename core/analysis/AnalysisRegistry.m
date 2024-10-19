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

    methods (Static)
        function [processes, out_vars, out_data, num_out] = parseAnalysisNote(note)
            processes = split(note, ", ")';
            processes = processes(processes ~= "");
            if nargout == 1
                return
            end
            out_vars = string.empty;
            out_data = string.empty;
            for i = 1:length(processes)
                out_vars = [out_vars, AnalysisRegistry.(processes(i)).OutputVars]; %#ok<AGROW>
                out_data = [out_data, AnalysisRegistry.(processes(i)).OutputData]; %#ok<AGROW>
            end
            num_out = length(out_vars) + length(out_data);
        end
    end

end
