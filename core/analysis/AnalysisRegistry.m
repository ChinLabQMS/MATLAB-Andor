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
% Format: func(live, info, options)

function fitCenter(live, info, options)
    arguments
        live
        info 
        options.first_only = true
    end
    assert(all(isfield(info, ["camera", "label", "config"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    [xc, yc, xw, yw] = fitCenter2D(signal);
    live.Analysis.(info.camera).(info.label).XCenter = xc;
    live.Analysis.(info.camera).(info.label).YCenter = yc;
    live.Analysis.(info.camera).(info.label).XWidth = xw;
    live.Analysis.(info.camera).(info.label).YWidth = yw;
end

function fitGauss(live, info)
    assert(all(isfield(info, ["camera", "label", "config"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config));
    f = fitGauss2D(signal);
    live.Analysis.(info.camera).(info.label).GaussX = f.x0;
    live.Analysis.(info.camera).(info.label).GaussY = f.y0;
    live.Analysis.(info.camera).(info.label).GaussXWid = f.s1;
    live.Analysis.(info.camera).(info.label).GaussYWid = f.s2;
end

function calibLatR(live, info, options)
    arguments
        live
        info
        options.first_only = true
    end
    assert(all(isfield(info, ["camera", "label", "config", "lattice"])))
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    Lat = info.lattice.(info.camera);
    Lat.calibrateR(signal)
    live.Analysis.(info.camera).(info.label).LatX = Lat.R(1);
    live.Analysis.(info.camera).(info.label).LatY = Lat.R(2);
end

function calibLatO(live, info, options)
    arguments
        live
        info
        options
    end
    
end
