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
        FitCenter          (@fitCenter, ...
                           ["XCenter", "YCenter", "XWidth", "YWidth"])
        FitGaussXY         (@fitGaussXY_new, ...
                           ["GaussXC", "GaussYC", "GaussXW", "GaussYW"], ...
                           ["SumX", "SumY"])
        CalibLatR          (@calibLatR, ...
                           ["LatX", "LatY"])
        CalibLatO          (@calibLatO, ...
                           ["LatX", "LatY"])
        FitPSF             (@fitPSF, ...
                           ["PSFGaussXWid", "PSFGaussYWid", "StrehlRatioAiry", "NumIsolatedPeaks"])
        RecordMotorStatus  (@recordMotor, ...
                           ["Picomotor1", "Picomotor2", "Picomotor3", "Picomotor4"])
        ReconstructSites   (@reconstructSites)
        AnalyzeOccup       (@analyzeOccup, ...
                            ["ErrorRate", "LossRate", "AtomNumber", "MeanFilling"], ...
                            ["CountDistribution"])
        UpdateDeconvWeight (@updateDeconvWeight)
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
        options.ref_camera = "Andor19331"
        options.ref_label = "Image"
        options.crop_R_site = 15
        options.verbose = false
    end
    timer = tic;
    ref_signal = getSignalSum(live.Signal.(options.ref_camera).(options.ref_label), ...
        live.CameraManager.(options.ref_camera).Config.NumSubFrames, "first_only", true);
    signal = getSignalSum(live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, "first_only", true);
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
        options.ratio = []
        options.verbose = false
    end
    timer = tic;
    PS = live.PSFCalib.(info.camera);
    signal = live.Signal.(info.camera).(info.label);
    if ~isempty(options.ratio)
        PS.setRatio(options.ratio)
    end
    PS.fit(signal, varargin{:})
    if PS.DataNumPeaks > 0
        live.Analysis.(info.camera).(info.label).PSFGaussXWid = PS.GaussGOF.eigen_widths(1);
        live.Analysis.(info.camera).(info.label).PSFGaussYWid = PS.GaussGOF.eigen_widths(2);
        live.Analysis.(info.camera).(info.label).StrehlRatioAiry = PS.StrehlRatioAiry;
        live.Analysis.(info.camera).(info.label).NumIsolatedPeaks = PS.DataNumPeaks;
    else
        live.Analysis.(info.camera).(info.label).PSFGaussXWid = nan;
        live.Analysis.(info.camera).(info.label).PSFGaussYWid = nan;
        live.Analysis.(info.camera).(info.label).StrehlRatioAiry = nan;
        live.Analysis.(info.camera).(info.label).NumIsolatedPeaks = nan;
    end
    if options.verbose
        live.info("[%s %s] Fitting PSF takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function recordMotor(live, info, options)
    arguments
       live
       info
       options.verbose = false
    end
    timer = tic;
    controller = live.CameraManager.(info.camera);
    for i = 1: 4
        motor_name = "Picomotor" + string(i);
        live.Analysis.(info.camera).(info.label).(motor_name) = controller.(motor_name).TargetPosition;
    end
    if options.verbose
        live.info("[%s %s] Recording Picomotor status takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function reconstructSites(live, info, varargin, options)
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
    counter = live.SiteCounters.(info.camera);
    live.Temporary.(info.camera).(info.label).SiteStat = counter.process( ...
        live.Signal.(info.camera).(info.label), ...
        info.config.NumSubFrames, ...
        varargin{:});
    if options.verbose
        live.info("[%s %s] Reconstructing sites takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function analyzeOccup(live, info, options)
    arguments
       live
       info
       options.hist_params = []
       options.verbose = false
    end
    timer = tic;
    if isfield(live.Temporary, info.camera) && isfield(live.Temporary.(info.camera), info.label) ...
        && isfield(live.Temporary.(info.camera).(info.label), "SiteStat")
        stat = live.Temporary.(info.camera).(info.label).SiteStat;
    else
        obj.warn2("[%s %s] Unable to find SiteStat in live data. Please check if 'ReconstructSites' appears in SequenceTable.", ...
            info.camera, info.label)
    end
    if ~isempty(options.hist_params)
        [N, edges] = histcounts(stat.LatCount(:), options.hist_params);
    else
        [N, edges] = histcounts(stat.LatCount(:));
    end
    live.Analysis.(info.camera).(info.label).CountDistribution = {{"histogram", N, edges, stat.LatThreshold}};
    if isfield(stat, "LatOccup")
        description = SiteCounter.describe(stat.LatOccup);
        live.Analysis.(info.camera).(info.label).ErrorRate = description.MeanAll.ErrorRate;
        live.Analysis.(info.camera).(info.label).LossRate = description.MeanAll.LossRate;
        live.Analysis.(info.camera).(info.label).AtomNumber = description.MeanAll.N;
        live.Analysis.(info.camera).(info.label).MeanFilling = description.MeanAll.F;
    else
        live.Analysis.(info.camera).(info.label).ErrorRate = nan;
        live.Analysis.(info.camera).(info.label).LossRate = nan;
        live.Analysis.(info.camera).(info.label).AtomNumber = nan;
        live.Analysis.(info.camera).(info.label).MeanFilling = nan;
        obj.warn2("[%s %s] Unable to find LatOccup in live data. Please check if 'ReconstructSites' appears in SequenceTable and has classify_method set.", ...
            info.camera, info.label)
    end
    if options.verbose
        live.info("[%s %s] Analyzing sites occupancies takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end

function updateDeconvWeight(live, info, options)
    arguments
       live
       info
       options.verbose = false
    end
    timer = tic;
    counter = live.SiteCounters.(info.camera);
    x_size = info.config.XPixels;
    y_size = info.config.YPixels;
    num_frames = info.config.NumSubFrames;
    counter.updateDeconvWeight(1: (x_size / num_frames), 1: y_size)
    if options.verbose
        live.info("[%s %s] Update deconvolution weights takes %5.3f s.", info.camera, info.label, toc(timer))
    end
end
