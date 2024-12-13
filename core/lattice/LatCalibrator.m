classdef LatCalibrator < DataProcessor
    %LATCALIBERATOR Calibrator for 
    % 1. Getting initial lattice calibration
    % 2. Re-calibrate to a different dataset
    % 3. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath
        LatCameraList = ["Andor19330", "Andor19331", "Zelux"]
        LatImageLabel = ["Image", "Image", "Lattice_935"]
        PSFCameraList = ["Andor19330", "Andor19331", "Zelux"]
        PSFImageLabel = ["Image", "Image", "Pattern_532"]
        InitAddCalibName = ["Zelux_532"]
        InitCropSize = [200, 200, 800]
    end

    properties (Constant)
        CalibRInit_PlotDiagnostic = true
        CalibVInit_PlotDiagnostic = true
        Copy_CalibName = "Zelux_935"
        Copy_CalibName2 = "Zelux_532"
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
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end

        % Plot FFT pattern of images for calibrating specific camera
        function plotFFT(obj, calib_name)
            s = obj.Stat.(calib_name);
            figure
            imagesc2(log(s.FFTPattern), 'title', calib_name)
            if ~isempty(obj.LatCalib.(calib_name).K)
                peak_pos = obj.LatCalib.(calib_name).convert2FFTPeak(size(s.FFTPattern));
                viscircles(peak_pos(:, 2:-1:1), 7, ...
                    "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
            end
        end
        
        % Calibrate the lattice vector from a single camera on mean image
        function calibrate(obj, calib_name, peak_init, center, opt1, opt2)
            arguments
                obj
                calib_name
                peak_init = []
                center = []
                opt1.plot_diagnosticR = obj.CalibRInit_PlotDiagnostic
                opt1.plot_diagnosticV = obj.CalibVInit_PlotDiagnostic
                opt2.crop_R_site = obj.CalibVRe_CropRSite
            end
            if ~isempty(peak_init)
                args = namedargs2cell(opt1);
                obj.calibrateInit(calib_name, peak_init, center, args{:})
            else
                args = [namedargs2cell(opt1), namedargs2cell(opt2)];
                obj.calibrateRe(calib_name, args{:})
            end
            disp(obj.LatCalib.(calib_name))
        end

        function copyCalib(obj, calib_name, calib_name2)
            arguments
                obj
                calib_name = obj.Copy_CalibName
                calib_name2 = obj.Copy_CalibName2
            end
            obj.assert(length(calib_name) == length(calib_name2), ...
                'Length of calib_name and calib_name2 must be equal')
            for i = 1: length(calib_name)
                calib1 = calib_name(i);
                calib2 = calib_name2(i);
                obj.LatCalib.(calib2).init([], obj.LatCalib.(calib1), 'format', "Lat")
                obj.info('Calibration is copied from %s to %s.', calib1, calib2)
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
                getNumFrames(obj.Signal.(opt3.camera).Config), "first_only", true);
            signal2 = getSignalSum(obj.Signal.(opt3.camera2).(opt3.label2)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(opt3.camera2).Config), "first_only", true);
            args = namedargs2cell(opt4);
            Lat = obj.LatCalib.(getCalibName(opt3.camera, opt3.label));
            Lat2 = obj.LatCalib.(getCalibName(opt3.camera2, opt3.label2));
            Lat.calibrateOCropSite(Lat2, signal, signal2, opt3.crop_R_site, args{:});
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
                opt3.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if opt.reset_centers
                for i = 1: length(obj.LatCameraList)
                    camera = obj.LatCameraList(i);
                    label = obj.LatImageLabel(i);
                    calib_name = getCalibName(camera, label);
                    obj.LatCalib.(calib_name).init(obj.Stat.(calib_name).Center, ...
                        'verbose', true)
                end
            end
            args1 = namedargs2cell(opt1);
            for i = 1: length(obj.LatCameraList)
                camera = obj.LatCameraList(i);
                label = obj.LatImageLabel(i);
                calib_name = getCalibName(camera, label);
                if ~isempty(obj.LatCalib.(calib_name).K)
                    obj.calibrate(calib_name, args1{:});
                else
                    obj.error("Unable to recalibrate camera [%s], please provide initial calibration either manually or through loading a file.", calib_name)
                end
            end
            if opt2.calibO
                args2 = namedargs2cell(opt3);
                obj.calibrateO(opt2.signal_index, args2{:});
            end
        end

        function calibratePSF(obj, options)
            arguments
                obj
                options
            end
            
        end
        
        % Save the calibration result to file
        function save(obj, filename, options)
            arguments
                obj
                filename = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
                options.copy_before_save = obj.Save_CopyBeforeSave
            end
            for i = 1: length(obj.LatCameraList)
                if ~isfield(obj.LatCalib, getCalibName(obj.LatCameraList(i), obj.LatImageLabel(i)))
                    obj.warn("Camera %s is not calibrated to label %s.", obj.LatCameraList(i), obj.LatImageLabel(i))
                end
            end
            Lat = obj.LatCalib;
            if options.copy_before_save
                obj.copyCalib()
            end
            Lat.Config = obj.struct();
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
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
                    calib_name = getCalibName(obj.CalibO_Camera, obj.CalibO_Label);
                    calib_name2 = getCalibName(obj.CalibO_Camera2, obj.CalibO_Label2);
                    Lat = obj.LatCalib.(calib_name);
                    Lat2 = obj.LatCalib.(calib_name2);
                    if ~isequal(Lat.Ostat.Site, [0, 0])
                        obj.warn("RunNumber = %d, lattice shifted.", i)
                        if options.drop_shifted
                            continue
                        end
                    end
                    result.(calib_name)(i) = Lat.Rstat;
                    result.(calib_name2)(i) = Lat2.Rstat;
                end
                for j = 1: length(obj.LatCameraList)
                    camera = obj.LatCameraList(j);
                    label = obj.LatImageLabel(j);
                    calib_name = getCalibName(camera, label);
                    if options.calibO_every && ismember(calib_name, ...
                            [getCalibName(obj.CalibO_Camera, obj.CalibO_Label), ...
                             getCalibName(obj.CalibO_Camera2, obj.CalibO_Label2)])
                        continue
                    end
                    signal = obj.Signal.(camera).(label)(:, :, i);
                    signal = getSignalSum(signal, getNumFrames(obj.Signal.(camera).Config));
                    Lat = obj.LatCalib.(calib_name);
                    Lat.calibrateRCropSite(signal, options.crop_R_site, "bootstrapping", true);
                    result.(calib_name)(i) = Lat.Rstat;
                end
            end
            if options.calibO_end
                obj.calibrateO(num_acq, "calib_R", false, "plot_diagnosticO", false, "verbose", false);
            end
            for j = 1:length(obj.LatCameraList)
                camera = obj.LatCameraList(j);
                label = obj.LatImageLabel(j);
                calib_name = getCalibName(camera, label);
                result.(calib_name) = struct2table(result.(calib_name));
                if isfield(obj.Signal.(camera).Config, "DataTimestamp")
                    result.(calib_name).DataTimestamp = obj.Signal.(camera).Config.DataTimestamp(1: num_acq);
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
        % Generate stats (cloud centers, widths, FFT pattern, ...) for lattice calibration
        function init(obj)
            if isempty(obj.DataPath)
                obj.error('DataPath not set!')
            end
            for i = 1: length(obj.LatCameraList)
                camera = obj.LatCameraList(i);
                label = obj.LatImageLabel(i);
                [calib_name, wavelength] = getCalibName(camera, label);
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);    
                if isempty(obj.InitCropSize)
                    [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                    s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                else
                    [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], obj.InitCropSize(i));
                    s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                end
                s.Center = [xc, yc];
                s.Width = [xw, yw];
                obj.Stat.(calib_name) = s;
                
                if ~isfield(obj.LatCalib, calib_name)
                    pixel_size = obj.Signal.(camera).Config.PixelSize;
                    obj.LatCalib.(calib_name) = Lattice(camera, wavelength, pixel_size);
                    obj.info("Empty Lattice object created for %s.", calib_name)
                end                
            end
            for calib_name = obj.InitAddCalibName
                if ~isfield(obj.LatCalib, calib_name)
                    [camera, wavelength] = getCameraAndWavelength(calib_name);
                    if isfield(obj.Signal, camera)
                        pixel_size = obj.Signal.(camera).Config.PixelSize;
                    else
                        obj.error('Not implemented for %s!', calib_name)
                    end
                    obj.LatCalib.(calib_name) = Lattice(camera, wavelength, pixel_size);
                        obj.info("Empty Lattice object created for %s.", calib_name)
                end
            end
            obj.info("Finish processing to get averaged images and basic statistics.")
        end

        function loadLatCalibFile(obj)
            if ~isempty(obj.LatCalibFilePath)
                obj.LatCalib = load(obj.LatCalibFilePath);
                obj.info("Pre-calibration loaded from: '%s'.", obj.LatCalibFilePath)
            else
                obj.LatCalib = [];
            end
        end

        % If initialize calibration with manual input peak positions,
        % assuming the positions are from processed FFT image
        function calibrateInit(obj, calib_name, peak_init, center, opt1)
            arguments
                obj
                calib_name
                peak_init
                center = []
                opt1.plot_diagnosticV
                opt1.plot_diagnosticR
            end
            Lat = obj.LatCalib.(calib_name);
            if isempty(center) && isempty(Lat.R)
                center = obj.Stat.(calib_name).Center;
            end
            Lat.init(center, size(obj.Stat.(calib_name).FFTPattern), peak_init)
            Lat0 = Lat.struct();
            % Fine tune calibration with the FFT pattern
            Lat.calibrate( ...
                obj.Stat.(calib_name).FFTImage, obj.Stat.(calib_name).FFTX, obj.Stat.(calib_name).FFTY, ...
                "plot_diagnosticV", opt1.plot_diagnosticV, "plot_diagnosticR", opt1.plot_diagnosticR);
            Lattice.checkDiff(Lat0, Lat, "manual", "final");
        end
        
        % Tune the calibration around a pre-loaded calibration
        function calibrateRe(obj, calib_name, opt1, opt2)
            arguments
                obj 
                calib_name
                opt1.plot_diagnosticV
                opt1.plot_diagnosticR
                opt2.crop_R_site
            end
            Lat = obj.LatCalib.(calib_name);
            Lat0 = Lat.struct();
            signal = obj.Stat.(calib_name).MeanImage;
            args = namedargs2cell(opt1);
            Lat.calibrateCropSite(signal, opt2.crop_R_site, args{:});
            Lattice.checkDiff(Lat0, Lat);
        end
    end

end
