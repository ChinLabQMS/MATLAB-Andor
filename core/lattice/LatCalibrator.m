classdef LatCalibrator < DataProcessor
    %LATCALIBERATOR Calibrator for 
    % 1. Getting initial lattice calibration
    % 2. Re-calibrate to a different dataset
    % 3. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241028.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
    end

    properties (Constant)
        CalibRInit_PlotDiagnostic = true
        CalibVInit_PlotDiagnostic = true
        CalibVRe_CropRSite = 20
        CalibO_CropRSite = 20
        CalibO_PlotDiagnostic = true
        CalibO_Camera = "Andor19331"
        CalibO_Camera2 = "Andor19330"
        CalibO_Label = "Image"
        CalibO_Label2 = "Image"
        CalibO_SignalIndex = 1
        CalibO_CalibR = true
        CalibO_CalibR_Bootstrap = false
        CalibO_Sites = Lattice.prepareSite('hex', 'latr', 5)
        CalibO_Verbose = true
        CalibO_VerboseStep = false
        CalibO_Debug = false
        Recalib_ResetCenters = true
        Recalib_CalibO = true
        TrackCalib_CropRSite = 20
        TrackCalib_CalibOFirst = true
        TrackCalib_CalibOEnd = true
        TrackCalib_CalibOEvery = true
        TrackCalib_DropShifted = false
    end

    properties (SetAccess = protected)
        Stat
        LatCalib
    end
    
    methods
        function set.LatCalibFilePath(obj, path)
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end

        % Plot FFT pattern of images acquired by specified camera
        function plotFFT(obj, camera)
            s = obj.Stat.(camera);
            figure
            imagesc2(log(s.FFTPattern), 'title', camera)
            if ~isempty(obj.LatCalib.(camera).K)
                peak_pos = obj.LatCalib.(camera).convert2FFTPeak(size(s.FFTPattern));
                viscircles(peak_pos(:, 2:-1:1), 7, ...
                    "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
            end
        end
        
        % Calibrate the lattice vector from a single camera on mean image
        function calibrate(obj, camera, peak_init, center, opt1, opt2)
            arguments
                obj
                camera
                peak_init = []
                center = []
                opt1.plot_diagnosticR = obj.CalibRInit_PlotDiagnostic
                opt1.plot_diagnosticV = obj.CalibVInit_PlotDiagnostic
                opt2.crop_R_site = obj.CalibVRe_CropRSite
            end
            if ~isempty(peak_init)
                args = namedargs2cell(opt1);
                obj.calibrateInit(camera, peak_init, center, args{:})
            else
                args = namedargs2cell(opt2);
                obj.calibrateRe(camera, args{:})
            end
        end

        % Cross-calibrate the lattice origin of camera to match camera2 on
        % matching patterns from a single acquisition
        function calibrateO(obj, signal_index, opt3, opt4)
            arguments
                obj
                signal_index = 1
                opt3.camera = obj.CalibO_Camera
                opt3.camera2 = obj.CalibO_Camera2
                opt3.label = obj.CalibO_Label
                opt3.label2 = obj.CalibO_Label2
                opt3.crop_R_site = obj.CalibO_CropRSite
                opt4.calib_R = obj.CalibO_CalibR
                opt4.calib_R_bootstrap = obj.CalibO_CalibR_Bootstrap
                opt4.sites = obj.CalibO_Sites
                opt4.verbose = obj.CalibO_Verbose
                opt4.verbose_step = obj.CalibO_VerboseStep
                opt4.plot_diagnosticO = obj.CalibO_PlotDiagnostic
                opt4.debug = obj.CalibO_Debug
            end
            signal = getSignalSum(obj.Signal.(opt3.camera).(opt3.label)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(opt3.camera).Config), "first_only", true);
            signal2 = getSignalSum(obj.Signal.(opt3.camera2).(opt3.label2)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(opt3.camera2).Config), "first_only", true);
            args = namedargs2cell(opt4);
            Lat = obj.LatCalib.(opt3.camera);
            Lat2 = obj.LatCalib.(opt3.camera2);
            Lat.calibrateOCropSite(Lat2, signal, signal2, opt3.crop_R_site, opt3.crop_R_site, args{:});
        end
        
        % Re-calibrate the lattice vectors and centers to mean image
        function recalibrate(obj, opt, opt1, opt2, opt3)
            arguments
                obj
                opt.reset_centers = obj.Recalib_ResetCenters
                opt1.plot_diagnosticR = obj.CalibRInit_PlotDiagnostic
                opt1.plot_diagnosticV = obj.CalibVInit_PlotDiagnostic
                opt2.calibO = obj.Recalib_CalibO
                opt2.signal_index = 1
                opt3.camera = obj.CalibO_Camera
                opt3.camera2 = obj.CalibO_Camera2
                opt3.label = obj.CalibO_Label
                opt3.label2 = obj.CalibO_Label2
                opt3.crop_R_site = obj.CalibO_CropRSite
                opt3.calib_R = obj.CalibO_CalibR
                opt3.sites = obj.CalibO_Sites
                opt3.verbose = obj.CalibO_Verbose
                opt3.verbose_step = obj.CalibO_VerboseStep
                opt3.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if opt.reset_centers
                for camera = obj.CameraList
                    obj.LatCalib.(camera).init(obj.Stat.(camera).Center)
                end
            end
            args1 = namedargs2cell(opt1);
            for camera = obj.CameraList
                if ~isempty(obj.LatCalib.(camera).K)
                    obj.calibrate(camera, args1{:});
                else
                    obj.error("Unable to recalibrate camera [%s], please provide initial calibration either manually or through loading a file.", camera)
                end
            end
            if opt2.calibO
                args2 = namedargs2cell(opt3);
                obj.calibrateO(opt2.signal_index, args2{:});
            end
        end
        
        % Save the calibration result to file
        function save(obj, filename)
            arguments
                obj
                filename = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
            end
            for camera = obj.CameraList
                if ~isfield(obj.LatCalib, camera)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            Lat = obj.LatCalib;
            Lat.Config = obj.struct();
            filename = filename.strip("right", ".mat");
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "Lat")
            obj.info("Lattice calibration saved as '%s'.", filename)
        end

        function result = trackCalib(obj, options)
            arguments
                obj
                options.crop_R_site = obj.TrackCalib_CropRSite
                options.calibO_first = obj.TrackCalib_CalibOFirst
                options.calibO_end = obj.TrackCalib_CalibOEnd
                options.calibO_every = obj.TrackCalib_CalibOEvery 
                options.drop_shifted = obj.TrackCalib_DropShifted
            end
            obj.info('Start generating lattice offset tracking report...')
            num_acq = obj.Signal.AcquisitionConfig.NumAcquisitions;
            result = struct();
            if options.calibO_first
                obj.info('Cross calibration on the first image...')
                obj.calibrateO(1, "crop_R_site", options.crop_R_site, ...
                    "plot_diagnosticO", false, "verbose", true, ...
                    "sites", Lattice.prepareSite('hex', 'latr', 20))
            end
            for i = 1: num_acq
                if options.calibO_every
                    obj.calibrateO(i, "calib_R", true, "calib_R_bootstrap", true, ...
                        "crop_R_site", options.crop_R_site, ...
                        "plot_diagnostic", false, "verbose", false, 'debug', options.drop_shifted)
                    Lat = obj.LatCalib.(obj.CalibO_Camera);
                    Lat2 = obj.LatCalib.(obj.CalibO_Camera2);
                    if ~isequal(Lat.Ostat.Site, [0, 0])
                        obj.warn("RunNumber = %d, lattice shifted.", i)
                        if options.drop_shifted
                            continue
                        end
                    end
                    result.(obj.CalibO_Camera)(i) = Lat.Rstat;
                    result.(obj.CalibO_Camera2)(i) = Lat2.Rstat;
                end
                for j = 1: length(obj.CameraList)
                    camera = obj.CameraList(j);
                    label = obj.ImageLabel(j);
                    Lat = obj.LatCalib.(camera);
                    if options.calibO_every && ismember(camera, [obj.CalibO_Camera, obj.CalibO_Camera2])                        
                        continue
                    end
                    signal = obj.Signal.(camera).(label)(:, :, i);
                    signal = getSignalSum(signal, getNumFrames(obj.Signal.(camera).Config));
                    Lat.calibrateRCropSite(signal, options.crop_R_site, "bootstrapping", true);
                    result.(camera)(i) = Lat.Rstat;
                end
            end
            if options.calibO_end
                obj.calibrateO(num_acq, "calib_R", false, "plot_diagnosticO", false, "verbose", false);
            end
            for j = 1:length(obj.CameraList)
                camera = obj.CameraList(j);
                result.(camera) = struct2table(result.(camera));
                if isfield(obj.Signal.(camera).Config, "DataTimestamp")
                    result.(camera).DataTimestamp = obj.Signal.(camera).Config.DataTimestamp(1: num_acq);
                end
            end
            obj.info('Lattice offset tracking report is generated.')
        end
    end

    methods (Access = protected, Hidden)
        % Generate stats (cloud centers, widths, FFT pattern, ...) for lattice calibration
        function init(obj)
            if isempty(obj.DataPath)
                obj.error('DataPath not set!')
            end
            for i = 1: length(obj.CameraList)
                camera = obj.CameraList(i);
                label = obj.ImageLabel(i);
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);                
                [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];
                obj.Stat.(camera) = s;
            end
            obj.info("Finish processing to get averaged images and basic statistics.")
        end

        function loadLatCalibFile(obj)
            if ~isempty(obj.LatCalibFilePath)
                obj.LatCalib = load(obj.LatCalibFilePath);
                obj.info("Pre-calibration loaded from: '%s'.", obj.LatCalibFilePath)
            else
                obj.LatCalib = [];
                for camera = obj.CameraList
                    obj.LatCalib.(camera) = Lattice(camera);
                    obj.info("Empty Lattice object created for camera %s.", camera)
                end
            end
        end

        % If initialize calibration with manual input peak positions,
        % assuming the positions are from processed FFT image
        function calibrateInit(obj, camera, peak_init, center, opt1)
            arguments
                obj
                camera
                peak_init
                center = []
                opt1.plot_diagnosticV
                opt1.plot_diagnosticR
            end
            Lat = obj.LatCalib.(camera);
            if isempty(center) && isempty(Lat.R)
                center = obj.Stat.(camera).Center;
            end
            Lat.init(center, size(obj.Stat.(camera).FFTPattern), peak_init)
            Lat0 = Lat.struct();
            Lat0.ID = camera + "_manual";
            % Fine tune calibration with the FFT pattern
            Lat.calibrate( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnosticV", opt1.plot_diagnosticV, "plot_diagnosticR", opt1.plot_diagnosticR);
            Lattice.checkDiff(Lat0, Lat);
        end
        
        % Tune the calibration around a pre-loaded calibration
        function calibrateRe(obj, camera, opt2)
            arguments
                obj 
                camera
                opt2.crop_R_site
            end
            Lat = obj.LatCalib.(camera);
            Lat0 = Lat.struct();
            Lat0.ID = camera + "_previous";
            signal = obj.Stat.(camera).MeanImage;
            Lat.calibrateCropSite(signal, opt2.crop_R_site);
            Lattice.checkDiff(Lat0, Lat);
        end
    end

end
