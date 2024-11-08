classdef AnalysisRegistry < BaseObject

    properties
        FuncHandle
        OutputVars
        OutputData
    end
    
    methods
        function obj = AnalysisRegistry(func, out_vars, out_data)
            arguments
                func
                out_vars = []
                out_data = []
            end
            obj.FuncHandle = func;
            obj.OutputVars = out_vars;
            obj.OutputData = out_data;
        end
    end

    enumeration
        FitCenter (@fitCenter, ...
                   ["XCenter", "YCenter", "XWidth", "YWidth"], ...
                   [])
        FitGauss  (@fitGauss, ...
                   ["GaussXC", "GaussYC", "GaussXWid", "GaussYWid"], ...
                   [])
        CalibLatR (@calibLatR, ...
                   ["LatX", "LatY"], ...
                   [])
        CalibLatO (@calibLatO, ...
                   ["LatX", "LatY"], ...
                   [])
        FitPSF    (@fitPSF, ...
                   ["SigmaX", "SigmaY", "StrehlRatio"], ...
                   ["PSFImage"])
    end

end

%% Registered functions in AnalysisRegistry
% Format: res = func(res, live, info, options)

function res = fitCenter(res, live, info, options)
    arguments
        res 
        live
        info 
        options.first_only = true
    end
    assert(all(isfield(info, ["camera", "label", "config"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    [res.XCenter, res.YCenter, res.XWidth, res.YWidth] = fitCenter2D(signal);
end

function res = fitGauss(res, live, info)
    assert(all(isfield(info, ["camera", "label", "config"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config));
    f = fitGauss2D(signal);
    res.GaussX = f.x0;
    res.GaussY = f.y0;
    res.GaussXWid = f.s1;
    res.GaussYWid = f.s2;
end

function res = calibLatR(res, live, info, options)
    arguments
        res
        live
        info
        options.first_only = true
    end
    assert(all(isfield(info, ["camera", "label", "config", "lattice"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    Lat = info.lattice.(info.camera);
    Lat.calibrateR(signal)
    res.LatX = Lat.R(1);
    res.LatY = Lat.R(2);
end

function res = calibLatO(res, live, info, options)
    arguments
        res
        live
        info
        options
    end
    
end
