classdef AnalysisRegistry < BaseObject

    properties
        OutputVars
        OutputData
        FuncHandle
    end
    
    methods
        function obj = AnalysisRegistry(out_vars, out_data, func)
            obj.OutputVars = out_vars;
            obj.OutputData = out_data;
            obj.FuncHandle = func;
        end
    end

    enumeration
        FitCenter (["XCenter", "YCenter", "XWidth", "YWidth"], ...
                   [], ...
                   @fitCenter)
        FitGauss  (["GaussX", "GaussY", "GaussXWid", "GaussYWid"], ...
                   [], ...
                   @fitGauss)
        CalibLatR (["LatX", "LatY"], ...
                   [], ...
                   @calibLatR)
    end

    methods (Static)
        function [processes, out_vars, out_data, num_out] = parseOutput(note)
            processes = {};
            args = parseString2Args(note, "output_format", "name-value");
            name = args{1};
            value = args{2};
            [~, s] = enumeration('AnalysisRegistry');
            process_names = string.empty();
            for i = 1:length(name)
                if ismember(name(i), s) && value(i)
                    process_names = [process_names, name(i)]; %#ok<AGROW>
                    processes = [processes, {{AnalysisRegistry.(name(i)).FuncHandle}}]; %#ok<AGROW>
                elseif ~isempty(process_names)
                    processes{end} = [processes{end}, {name(i), value(i)}];
                else
                    error("Parameters appears before named process.")
                end
            end
            if nargout == 1
                return
            end
            out_vars = string.empty;
            out_data = string.empty;
            for p = process_names
                out_vars = [out_vars, AnalysisRegistry.(p).OutputVars]; %#ok<AGROW>
                out_data = [out_data, AnalysisRegistry.(p).OutputData]; %#ok<AGROW>
            end
            num_out = length(out_vars) + length(out_data);
        end
    end

end

%% Registered functions in AnalysisRegistry
% Format: res = func(res, signal, info, options)

function res = fitCenter(res, signal, info, options)
    arguments
        res 
        signal 
        info 
        options.first_only = true
    end
    assert(all(isfield(info, "config")))
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    [res.XCenter, res.YCenter, res.XWidth, res.YWidth] = fitCenter2D(signal);
end

function res = fitGauss(res, signal, info)
    assert(all(isfield(info, "config")))
    signal = getSignalSum(signal, getNumFrames(info.config));
    f = fitGauss2D(signal);
    res.GaussX = f.x0;
    res.GaussY = f.y0;
    res.GaussXWid = f.s1;
    res.GaussYWid = f.s2;
end

function res = calibLatR(res, signal, info, options)
    arguments
        res
        signal
        info
        options.first_only = true
    end
    assert(all(isfield(info, ["camera", "config", "lattice"])))
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    Lat = info.lattice.(info.camera);
    Lat.calibrateR(signal)
    res.LatX = Lat.R(1);
    res.LatY = Lat.R(2);
end
