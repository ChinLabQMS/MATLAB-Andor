classdef AnalysisRegistry < BaseObject
    %ANALYSISREGISTRY A collection of wrappers for real-time analysis
    % The majority part of the code should be written outside of this
    % class, while leaving only a thin wrapper here to connect to the app
    % sequence runner.

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
        FitCenter      (@fitCenter, ...
                       ["XCenter", "YCenter", "XWidth", "YWidth"])
        FitGauss       (@fitGaussXY_new, ...
                       ["GaussXC", "GaussYC", "GaussXW", "GaussYW"], ...
                       ["SumX", "SumY"])
        CalibLatR      (@calibLatR, ...
                       ["LatX", "LatY"])
        CalibLatO      (@calibLatO, ...
                       ["LatX", "LatY"])
        FitPSF         (@fitPSF, ...
                       ["PSFGaussXWid", "PSFGaussYWid", "StrehlRatioAiry", "NumIsolatedPeaks"])
    end

end

%% Registered functions in AnalysisRegistry
% Format: func(live, info, options)
%   - info: structure containing 'camera', 'label', 'config' as fields
%   - options: optional name-value pairs that could be input in the
%              SequenceTable

function fitCenter(live, info, options)
    arguments
        live
        info 
        options.first_only = true
        options.verbose = false
    end
    timer = tic;
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, "first_only", options.first_only);
    [xc, yc, xw, yw] = fitCenter2D(signal);
    live.Analysis.(info.camera).(info.label).XCenter = xc;
    live.Analysis.(info.camera).(info.label).YCenter = yc;
    live.Analysis.(info.camera).(info.label).XWidth = xw;
    live.Analysis.(info.camera).(info.label).YWidth = yw;
    if options.verbose
        live.info("[%s %s] Fitting cloud centers takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function fitGaussXY_new(live, info, options)
    arguments
        live
        info 
        options.first_only = true
        options.verbose = false
    end
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, "first_only", options.first_only);
    [xc, yc, xw, yw, ~, ~, xsum, ysum] = fitGaussXY(signal);
    live.Analysis.(info.camera).(info.label).GaussXC = xc;
    live.Analysis.(info.camera).(info.label).GaussYC = yc;
    live.Analysis.(info.camera).(info.label).GaussXW = xw;
    live.Analysis.(info.camera).(info.label).GaussYW = yw;
    live.Analysis.(info.camera).(info.label).SumX = {xsum};
    live.Analysis.(info.camera).(info.label).SumY = {ysum};
    if options.verbose
        live.info("[%s %s] Fitting cloud centers (GaussXY) takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function calibLatR(live, info, varargin, options)
    arguments
        live
        info
    end
    arguments (Repeating)
        varargin
    end
    arguments
        options.first_only = false
        options.verbose = false
    end
    timer = tic;
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, "first_only", options.first_only);
    Lat = live.LatCalib.(info.camera);
    Lat.calibrateR(signal, varargin{:})
    live.Analysis.(info.camera).(info.label).LatX = Lat.R(1);
    live.Analysis.(info.camera).(info.label).LatY = Lat.R(2);
    if options.verbose
        live.info("[%s %s] Calibrating lattice R takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function calibLatO(live, info, varargin, options)
    arguments
        live
        info
    end
    arguments (Repeating)
        varargin
    end
    arguments
        options.ref_camera = "Andor19330"
        options.ref_label = "Image"
        options.crop_R_site = 15
        options.first_only = true
        options.verbose = false
    end
    timer = tic;
    ref_signal = getSignalSum(live.Signal.(options.ref_camera).(options.ref_label), ...
        live.CameraManager.(options.ref_camera).Config.NumSubFrames, "first_only", true);
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, "first_only", options.first_only);
    Lat = live.LatCalib.(info.camera);
    Lat_ref = live.LatCalib.(options.ref_camera);
    Lat.calibrateOCropSite(Lat_ref, signal, ref_signal, options.crop_R_site, ...
        'calib_R', [1, 0], varargin{:})
    live.Analysis.(info.camera).(info.label).LatX = Lat.R(1);
    live.Analysis.(info.camera).(info.label).LatY = Lat.R(2);
    if options.verbose
        live.info("[%s %s] Cross calibrating lattice R takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function fitPSF(live, info, varargin, options)
    arguments
        live
        info
    end
    arguments (Repeating)
        varargin
    end
    arguments
        options.verbose = false
    end
    timer = tic;
    PS = live.PSFCalib.(info.camera);
    signal = live.Signal.(info.camera).(info.label);
    PS.fit(signal, varargin{:})
    if PS.DataNumPeaks > 0
        live.Analysis.(info.camera).(info.label).PSFGaussXWid = PS.GaussGOF.eigen_widths(1);
        live.Analysis.(info.camera).(info.label).PSFGaussYWid = PS.GaussGOF.eigen_widths(2);
        live.Analysis.(info.camera).(info.label).StrehlRatioAiry = PS.StrehlRatioAiry;
        live.Analysis.(info.camera).(info.label).NumIsolatedPeaks = PS.DataNumPeaks;
    end
    if options.verbose
        live.info("[%s %s] Fitting PSF takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

%% Other utilities functions

