classdef AnalysisRegistry < BaseObject

    properties
        OutputVars
        OutputData
        FuncHandle
    end
    
    methods
        function obj = AnalysisRegistry(out_vars, out_data, func)
            arguments
                out_vars (1, :) string
                out_data (1, :) string
                func (1, 1) function_handle
            end
            obj.OutputVars = out_vars;
            obj.OutputData = out_data;
            obj.FuncHandle = func;
        end
    end

    enumeration
        FitCenter (["XCenter", "YCenter", "XWidth", "YWidth"], [], @fitCenter)
        FitGauss  (["GaussX", "GaussY", "GaussXWid", "GaussYWid"], [], @fitGauss)
        CalibLatR (["LatX", "LatY"], [], @calibLatR)
    end

    methods (Static)
        function [processes, out_vars, out_data, num_out] = parseOutput(note)
            processes = struct();
            args = parseString2Args(note, "output_format", "name-value");
            name = args{1};
            value = args{2};
            [~, s] = enumeration('AnalysisRegistry');
            for i = 1:length(name)
                if ismember(name(i), s) && value(i)
                    curr = name(i);
                    processes.(curr).Func = AnalysisRegistry.(name(i)).FuncHandle;
                    processes.(curr).Args = {};
                else
                    processes.(curr).Args = [processes.(curr).Args, {name(i), value(i)}];
                end
            end
            if nargout == 1
                return
            end
            out_vars = string.empty;
            out_data = string.empty;
            for p = string(fields(processes))'
                out_vars = [out_vars, AnalysisRegistry.(p).OutputVars]; %#ok<AGROW>
                out_data = [out_data, AnalysisRegistry.(p).OutputData]; %#ok<AGROW>
            end
            num_out = length(out_vars) + length(out_data);
        end
    end

end

%% Registered functions in AnalysisRegistry
% Format: res = func(res, analyzer, signal, label, cam_config, varargin)

function res = fitCenter(res, ~, signal, ~, config)
    signal = getSignalSum(signal, getNumFrames(config));
    [res.XCenter, res.YCenter, res.XWidth, res.YWidth] = fitCenter2D(signal);
end

function res = fitGauss(res, ~, signal, ~, ~)
    f = fitGauss2D(signal);
    res.GaussX = f.x0;
    res.GaussY = f.y0;
    res.GaussXWid = f.s1;
    res.GaussYWid = f.s2;
end

function res = calibLatR(res, analyzer, signal, ~, config, options)
    arguments
        res (1, 1) struct
        analyzer (1, 1) BaseProcessor
        signal (:, :) double
        ~
        config (1, 1) struct
        options.first_only = true
    end
    camera = config.CameraName;
    signal = getSignalSum(signal, getNumFrames(config), "first_only", options.first_only);
    Lat = analyzer.Lattice.(camera);
    Lat.calibrateR(signal)
    res.LatX = analyzer.Lattice.(camera).R(1);
    res.LatY = analyzer.Lattice.(camera).R(2);
end
