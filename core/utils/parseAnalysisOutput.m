function [processes, out_vars, out_data, num_out] = parseAnalysisOutput(note)
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
