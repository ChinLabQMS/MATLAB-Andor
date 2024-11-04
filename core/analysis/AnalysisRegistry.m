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
