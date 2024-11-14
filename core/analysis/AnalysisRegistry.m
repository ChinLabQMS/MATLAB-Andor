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
        options.verbose = false
    end
    timer = tic;
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    [xc, yc, xw, yw] = fitCenter2D(signal);
    live.Analysis.(info.camera).(info.label).XCenter = xc;
    live.Analysis.(info.camera).(info.label).YCenter = yc;
    live.Analysis.(info.camera).(info.label).XWidth = xw;
    live.Analysis.(info.camera).(info.label).YWidth = yw;
    if options.verbose
        live.info("Fitting centers takes %5.3f s.", toc(timer))
    end
end

function fitGauss(live, info)
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
        options.first_only = false
        options.verbose = false
    end
    timer = tic;
    signal = live.Signal.(info.camera).(info.label);
    signal = getSignalSum(signal, getNumFrames(info.config), "first_only", options.first_only);
    Lat = info.lattice.(info.camera);
    Lat.calibrateR(signal)
    live.Analysis.(info.camera).(info.label).LatX = Lat.R(1);
    live.Analysis.(info.camera).(info.label).LatY = Lat.R(2);
    if options.verbose
        live.info("Calibrating lattice R takes %5.3f s.", toc(timer))
    end
end

function calibLatO(live, info, options, options2)
    arguments
        live
        info
        options.ref_camera = "Andor19330"
        options.ref_label = "Image"
        options.crop_R_site = 15
        options.search_R_site = 3
        options2.verbose = false
    end
    timer = tic;
    ref_signal = getSignalSum(live.Signal.(options.ref_camera).(options.ref_label), ...
        getNumFrames(live.CameraManager.(options.ref_camera).Config), "first_only", true);
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        getNumFrames(live.CameraManager.(info.camera)), "first_only", true);
    Lat = live.LatCalib.(info.camera);
    Lat2 = live.LatCalib.(options.ref_camera);
    Lat.calibrateOCropSite(Lat2, signal, ref_signal, options.crop_R_site, options.crop_R_site)
    live.Analysis.(info.camera).(info.label).LatX = Lat.R(1);
    live.Analysis.(info.camera).(info.label).LatY = Lat.R(2);
    if options2.verbose && isa(live, "BaseObject")
        live.info("Cross calibrating lattice R takes %5.3f s.", toc(timer))
    end
end

function fitPSF(live, info, options)
    arguments
        live
        info
        options.thresh_percent = 0.5
        options.crop_size = 10
        options.verbose = false
    end
end
