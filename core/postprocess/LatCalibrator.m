classdef LatCalibrator < DataProcessor
    %LATCALIBERATOR Calibrator for 
    % 1. Getting initial lattice calibration
    % 2. Re-calibrate to a different dataset
    % 3. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241215.mat"
        InitCameraName = ["Andor19330", "Andor19331", "Zelux", "DMD"]
        LatCameraList = ["Andor19330", "Andor19331", "Zelux"]
        LatImageLabel = ["Image", "Image", "Lattice_935"]
    end

    properties (Constant)
        Process_BinThresholdPerct = 0.5
        Process_CropSize = [200; 200; inf]
        Calibrate_Binarize = true
        Calibrate_PlotDiagnosticR = true
        Calibrate_PlotDiagnosticV = true
        Calibrate_CropRSite = 20
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
        CalibO_Debug = false
        Recalib_ResetCenters = false
        Recalib_CalibO = true
        Save_CopyBeforeSave = true
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
            if isempty(path)
                obj.LatCalibFilePath = path;
                return
            end
            obj.loadLatCalibFile(path)
            obj.LatCalibFilePath = path;
        end
        
        % Generate stats (cloud centers, widths, FFT pattern, ...) for lattice calibration
        function process(obj, options)
            arguments
                obj
                options.bin_threshold_perct = obj.Process_BinThresholdPerct
                options.crop_size = obj.Process_CropSize
            end
            for i = 1: length(obj.LatCameraList)
                camera = obj.LatCameraList(i);
                label = obj.LatImageLabel(i);
                signal = obj.Signal.(camera).(label);
                signal_bin = signal;
                thres = options.bin_threshold_perct * max(signal(:));
                signal_bin(signal < thres) = 0;
                s.MeanImage = getSignalSum(signal, obj.Signal.(camera).Config.NumSubFrames);
                s.MeanImageBin = getSignalSum(signal_bin, obj.Signal.(camera).Config.NumSubFrames);
                [xc, yc, xw, yw] = fitGaussXY(s.MeanImage);
                if isempty(options.crop_size) || size(options.crop_size, 1) < i || all(options.crop_size(i, :) == 0)
                    options.crop_size(i, :) = 2 * [xw, yw];
                end
                [s.FFTImageAll, s.FFTX, s.FFTY] = prepareBox(signal, [xc, yc], options.crop_size(i, :));
                s.FFTImage = prepareBox(s.MeanImage, [xc, yc], options.crop_size(i, :));
                s.FFTImageBin = prepareBox(s.MeanImageBin, [xc, yc], options.crop_size(i, :));
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.FFTPatternBin = abs(fftshift(fft2(s.FFTImageBin)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];
                s.FFTSize = [length(s.FFTX), length(s.FFTY)];
                obj.Stat.(camera) = s;
            end
            obj.info("Finish processing to get averaged images and basic statistics.")
        end

        % Plot FFT pattern of images for calibrating specific camera
        function plotFFT(obj, camera)
            figure
            subplot(1, 2, 1)
            imagesc2(log(obj.Stat.(camera).FFTPattern), 'title', sprintf("%s mean", camera))
            addCircles()
            subplot(1, 2, 2)
            imagesc2(log(obj.Stat.(camera).FFTPatternBin), 'title', sprintf("%s filtered mean", camera))
            addCircles()
            function addCircles()
                if ~isempty(obj.LatCalib.(camera).K)
                    peak_pos = obj.LatCalib.(camera).convert2FFTPeak(obj.Stat.(camera).FFTSize);
                    viscircles(peak_pos(:, 2:-1:1), 7, ...
                        "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
                    hold on
                    for i = 1: size(peak_pos, 2)
                        x = peak_pos(i, 2);
                        y = peak_pos(i, 1);
                        text(x + 10, y, num2str(i), "FontSize", 16, 'Color', 'r')
                    end
                    hold off
                end
            end
        end
        
        % Calibrate the lattice vector from a single camera on mean image
        function calibrate(obj, camera, peak_init, center, opt1, opt2)
            arguments
                obj
                camera
                peak_init = []
                center = []
                opt1.binarize = obj.Calibrate_Binarize
                opt1.plot_diagnosticR = obj.Calibrate_PlotDiagnosticR
                opt1.plot_diagnosticV = obj.Calibrate_PlotDiagnosticV
                opt2.crop_R_site = obj.Calibrate_CropRSite
            end
            if ~isempty(peak_init)
                args = namedargs2cell(opt1);
                obj.calibrateInit(camera, peak_init, center, args{:})
            else
                args = [namedargs2cell(opt1), namedargs2cell(opt2)];
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
                opt4.plot_diagnosticO = obj.CalibO_PlotDiagnostic
                opt4.debug = obj.CalibO_Debug
            end
            signal = getSignalSum(obj.Signal.(opt3.camera).(opt3.label)(:, :, signal_index), ...
                obj.Signal.(opt3.camera).Config.NumSubFrames, "first_only", true);
            signal2 = getSignalSum(obj.Signal.(opt3.camera2).(opt3.label2)(:, :, signal_index), ...
                obj.Signal.(opt3.camera2).Config.NumSubFrames, "first_only", true);
            args = namedargs2cell(opt4);
            Lat = obj.LatCalib.(opt3.camera);
            Lat2 = obj.LatCalib.(opt3.camera2);
            Lat.calibrateOCropSite(Lat2, signal, signal2, opt3.crop_R_site, args{:});
        end
        
        % Re-calibrate the lattice vectors and centers to mean image
        function recalibrate(obj, opt, opt1, opt2, opt3)
            arguments
                obj
                opt.reset_centers = obj.Recalib_ResetCenters
                opt1.plot_diagnosticR = obj.Calibrate_PlotDiagnosticR
                opt1.plot_diagnosticV = obj.Calibrate_PlotDiagnosticV
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
                opt3.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if opt.reset_centers
                for i = 1: length(obj.LatCameraList)
                    camera = obj.LatCameraList(i);
                    obj.LatCalib.(camera).init(obj.Stat.(camera).Center, 'verbose', true)
                end
            end
            args1 = namedargs2cell(opt1);
            for i = 1: length(obj.LatCameraList)
                camera = obj.LatCameraList(i);
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
            for camera = obj.InitCameraName
                if isempty(obj.LatCalib.(camera).K)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            LatAll = obj.LatCalib;
            LatAll.Config = obj.struct();
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "LatAll")
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
                for j = 1: length(obj.LatCameraList)
                    camera = obj.LatCameraList(j);
                    label = obj.LatImageLabel(j);
                    if options.calibO_every && ismember(camera, ...
                            [obj.CalibO_Camera, obj.CalibO_Camera2])
                        continue
                    end
                    signal = obj.Signal.(camera).(label)(:, :, i);
                    signal = getSignalSum(signal, obj.Signal.(camera).Config.NumSubFrames);
                    Lat = obj.LatCalib.(camera);
                    Lat.calibrateRCropSite(signal, options.crop_R_site, "bootstrapping", true);
                    result.(camera)(i) = Lat.Rstat;
                end
            end
            if options.calibO_end
                obj.calibrateO(num_acq, "calib_R", false, "plot_diagnosticO", false, "verbose", false);
            end
            for camera = obj.LatCameraList
                result.(camera) = struct2table(result.(camera));
                if isfield(obj.Signal.(camera).Config, "DataTimestamp")
                    result.(camera).DataTimestamp = obj.Signal.(camera).Config.DataTimestamp(1: num_acq);
                end
            end
            obj.info('Lattice offset tracking report is generated.')
        end

        function disp(obj)
            disp@BaseProcessor(obj)
            for c = string(fields(obj.LatCalib))'
                disp(obj.LatCalib.(c))
            end
        end
    end

    methods (Access = protected, Hidden)
        function loadLatCalibFile(obj, path)
            obj.checkFilePath(path)
            obj.LatCalib = load(path);
            obj.info("Pre-calibration loaded from: '%s'.", path)
        end

        function init(obj)
            obj.checkFilePath(obj.DataPath, 'DataPath')
            for i = 1: length(obj.InitCameraName)
                camera = obj.InitCameraName(i);
                if ~isfield(obj.LatCalib, camera)
                    if isfield(obj.Signal, camera)
                        pixel_size = obj.Signal.(camera).Config.PixelSize;
                    else
                        %% TODO: grab pixel size from projector config
                        pixel_size = 7.637;
                    end
                    obj.LatCalib.(camera) = Lattice(camera, pixel_size);
                    obj.info('Empty Lattice object created for %s.', camera)
                else
                    obj.info('Found calibration for %s in loaded LatCalib file.', camera)
                end
            end
            obj.process()
        end

        % If initialize calibration with manual input peak positions,
        % assuming the positions are from processed FFT image
        function calibrateInit(obj, camera, peak_init, center, opt1)
            arguments
                obj
                camera
                peak_init
                center = []
                opt1.binarize
                opt1.plot_diagnosticV
                opt1.plot_diagnosticR
            end
            Lat = obj.LatCalib.(camera);
            if isempty(center) && isempty(Lat.R)
                center = obj.Stat.(camera).Center;
            end
            Lat.init(center, obj.Stat.(camera).FFTSize, peak_init)
            Lat0 = Lat.struct();
            % Fine tune calibration with the FFT pattern
            args = namedargs2cell(opt1);
            Lat.calibrate( ...
                obj.Stat.(camera).FFTImageAll, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, args{:});
            Lattice.checkDiff(Lat0, Lat, "manual", "final");
        end
        
        % Tune the calibration around a pre-loaded calibration
        function calibrateRe(obj, camera, opt1, opt2)
            arguments
                obj 
                camera
                opt1.binarize
                opt1.plot_diagnosticV
                opt1.plot_diagnosticR
                opt2.crop_R_site
            end
            Lat = obj.LatCalib.(camera);
            Lat0 = Lat.struct();
            signal = obj.Stat.(camera).MeanImage;
            args = namedargs2cell(opt1);
            Lat.calibrateCropSite(signal, opt2.crop_R_site, args{:});
            Lattice.checkDiff(Lat0, Lat);
        end
    end

end
