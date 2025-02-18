classdef LatCalibrator < DataProcessor & LatProcessor
    %LATCALIBERATOR Calibrator for 
    % 1. Getting initial lattice calibration
    % 2. Re-calibrate to a different dataset
    % 3. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        InitCameraName = ["Andor19330", "Andor19331", "Zelux", "DMD"]
        LatCameraList = ["Andor19330", "Andor19331", "Zelux"]
        LatImageLabel = ["Image", "Image", "Lattice_935"]
    end

    properties (Constant)
        Process_BinThresholdPerct = 0.3
        Process_CropSize = [200; 200; inf]
        Process_SignalLowerCrop = 8
        Calibrate_Binarize = true
        Calibrate_BinarizeThresPerct = 0.3
        Calibrate_PlotDiagnosticR = true
        Calibrate_PlotDiagnosticV = true
        CalibO_CropRSite = 20
        CalibO_PlotDiagnostic = true
        CalibO_Camera = "Andor19331"
        CalibO_Camera2 = "Andor19330"
        CalibO_Label = "Image"
        CalibO_Label2 = "Image"
        CalibO_SignalIndex = 1
        CalibO_CalibR = true
        CalibO_CalibR_Bootstrap = false
        CalibO_Sites = SiteGrid.prepareSite('Hex', 'latr', 5)
        CalibO_Verbose = true
        CalibO_Debug = false
        CalibDMD_Camera = "Zelux"
        CalibDMD_Label = "Pattern_532"
        Recalib_ResetCenters = false
        Recalib_BinarizeCameraList = ["Andor19330", "Andor19331"]
        Recalib_CalibO = true
        TrackCalib_CropRSite = 20
        TrackCalib_CalibOFirst = true
        TrackCalib_CalibOEnd = true
        TrackCalib_CalibOEvery = true
        TrackCalib_DropShifted = false
    end

    properties (SetAccess = protected)
        Stat
    end
    
    methods
        function obj = LatCalibrator(varargin)
            obj@DataProcessor('reset_fields', false, 'init', false)
            obj@LatProcessor(varargin{:}, 'reset_fields', true, 'init', true)
        end

        % Generate stats (cloud centers, widths, FFT pattern, ...) for lattice calibration
        function process(obj, options)
            arguments
                obj
                options.bin_threshold_perct = obj.Process_BinThresholdPerct
                options.crop_size = obj.Process_CropSize
                options.signal_lower_crop = obj.Process_SignalLowerCrop
            end
            for i = 1: length(obj.LatCameraList)
                camera = obj.LatCameraList(i);
                label = obj.LatImageLabel(i);
                signal = obj.Signal.(camera).(label);
                signal_bin = signal;
                thres = options.bin_threshold_perct * max(signal(:));
                signal_bin(signal < thres) = 0;
                s.Image = signal;
                s.MeanImage = getSignalSum(signal, obj.Signal.(camera).Config.NumSubFrames);
                s.MeanImageBin = getSignalSum(signal_bin, obj.Signal.(camera).Config.NumSubFrames);
                [xc, yc, xw, yw] = fitGaussXY(s.MeanImage( ...
                    1: (size(s.MeanImage, 1) - options.signal_lower_crop), :));
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
    
        % Plot an example of single shot signal
        function plotSignal(obj, options)
            arguments
                obj
                options.index = 1
            end
            num_cameras = length(obj.LatCameraList);
            figure
            sgtitle(sprintf('Image index: %d', options.index))
            for i = 1: num_cameras
                camera = obj.LatCameraList(i);
                lat = obj.LatCalib.(camera);
                s = obj.Stat.(camera);
                signal = s.Image(:, :, options.index);
                ax = subplot(1, num_cameras, i);
                imagesc2(ax, signal, 'title', camera)
                % Plot a circle around fitted gaussian
                h1 = viscircles(s.Center([2, 1]), mean(s.Width), ...
                                'Color', 'g', 'LineWidth', 1, 'LineStyle','--', 'EnhanceVisibility', 0);
                % Plot the lattice grid
                if ~isempty(obj.LatCalib.(camera).K)
                    lat.calibrateR(s.FFTImageAll(:, :, options.index), s.FFTX, s.FFTY)
                    h2 = lat.plot();
                    legend([h1, h2], ["fitted gaussian", "loaded calibration"])
                else
                    legend(h1, "fitted gaussian")
                end
            end
        end
        
        % Plot an example of transformed single shot signal
        function plotTransformed(obj, varargin, options)
            arguments
                obj
            end
            arguments (Repeating)
                varargin
            end
            arguments
                options.index = 1
            end
            num_cameras = length(obj.LatCameraList);
            figure
            sgtitle(sprintf('Image index: %d', options.index))
            for i = 1: num_cameras
                camera = obj.LatCameraList(i);
                lat = obj.LatCalib.(camera);
                s = obj.Stat.(camera);
                signal = s.Image(:, :, options.index);
                x_range = 1: size(signal, 1);
                y_range = 1: size(signal, 2);
                ax = subplot(1, num_cameras, i);
                [transformed, x_range2, y_range2, lat_std] = lat.transformSignalStandard(signal, x_range, y_range, varargin{:});
                imagesc2(ax, y_range2, x_range2, transformed, 'title', camera + "(transformed)")
                lat_std.plot();
                xlabel('X (um)')
                ylabel('Y (um)')
            end
        end

        % Plot FFT pattern of images for calibrating specific camera
        function plotFFT(obj, camera)
            s = obj.Stat.(camera);
            figure
            subplot(2, 2, 1)
            imagesc2(s.MeanImage, 'title', sprintf("%s mean", camera))
            viscircles(s.Center([2, 1]), mean(s.Width), ...
                'Color', 'w', 'LineWidth', 0.5, 'LineStyle', '--', 'EnhanceVisibility', 0);
            subplot(2, 2, 2)
            imagesc2(s.MeanImageBin, 'title', sprintf("%s filtered mean", camera))
            subplot(2, 2, 3)
            imagesc2(log(s.FFTPattern), 'title', sprintf("%s FFT (log) mean", camera))
            addCircles()
            subplot(2, 2, 4)
            imagesc2(log(s.FFTPatternBin), 'title', sprintf("%s FFT (log) filtered mean", camera))
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
        function calibrate(obj, camera, peak_init, center, opt)
            arguments
                obj
                camera
                peak_init = []
                center = []
                opt.binarize = obj.Calibrate_Binarize
                opt.binarize_thres_perct = obj.Calibrate_BinarizeThresPerct
                opt.plot_diagnosticR = obj.Calibrate_PlotDiagnosticR
                opt.plot_diagnosticV = obj.Calibrate_PlotDiagnosticV
            end
            args = namedargs2cell(opt);
            Lat = obj.LatCalib.(camera);
            if ~isempty(peak_init) % Initial calibration
                if isempty(center) && isempty(Lat.R)
                    center = obj.Stat.(camera).Center;
                end
                Lat.init(center, obj.Stat.(camera).FFTSize, peak_init)
            end
            Lat0 = Lat.struct();
            % Fine tune calibration with the FFT pattern
            Lat.calibrate( ...
                obj.Stat.(camera).FFTImageAll, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, args{:});
            Lattice.checkDiff(Lat0, Lat);
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
        
        % 
        function plotPattern(obj)
        end

        % Cross-calibrate the lattice vector of DMD frame based on Zelux
        % pattern image
        function calibrateDMD(obj, opt)
            arguments
                obj
                opt.camera = obj.CalibDMD_Camera
                opt.label = obj.CalibDMD_Label
            end
        end
        
        % Re-calibrate the lattice vectors and centers to mean image
        function recalibrate(obj, opt, opt1, opt2)
            arguments
                obj
                opt.reset_centers = obj.Recalib_ResetCenters
                opt.binarize_list = obj.Recalib_BinarizeCameraList
                opt.calibO = obj.Recalib_CalibO
                opt.signal_index = 1
                opt1.plot_diagnosticR = obj.Calibrate_PlotDiagnosticR
                opt1.plot_diagnosticV = obj.Calibrate_PlotDiagnosticV
                opt2.camera = obj.CalibO_Camera
                opt2.camera2 = obj.CalibO_Camera2
                opt2.label = obj.CalibO_Label
                opt2.label2 = obj.CalibO_Label2
                opt2.crop_R_site = obj.CalibO_CropRSite
                opt2.calib_R = obj.CalibO_CalibR
                opt2.sites = obj.CalibO_Sites
                opt2.verbose = obj.CalibO_Verbose
                opt2.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if opt.reset_centers
                for i = 1: length(obj.LatCameraList)
                    camera = obj.LatCameraList(i);
                    obj.LatCalib.(camera).init(obj.Stat.(camera).Center, 'verbose', true)
                end
            end
            args1 = namedargs2cell(opt1);
            for camera = obj.LatCameraList
                if ~isempty(obj.LatCalib.(camera).K)
                    obj.calibrate(camera, args1{:}, 'binarize', ismember(camera, opt.binarize_list));
                else
                    obj.error("Unable to recalibrate camera [%s], please provide initial calibration either manually or through loading a file.", camera)
                end
            end
            if opt.calibO
                args2 = namedargs2cell(opt2);
                obj.calibrateO(opt.signal_index, args2{:});
            end
        end
        
        % Save the calibration result to file
        function save(obj, filename, most_recent_filename)
            arguments
                obj
                filename = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
                most_recent_filename = "calibration/LatCalib.mat"
            end
            calib = obj.LatCalib;
            calib.Config = obj.struct();
            for camera = obj.InitCameraName
                if isempty(calib.(camera).K)
                    obj.warn2("Camera %s is not calibrated.", camera)
                end
            end
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "calib")
            save(most_recent_filename, "-struct", "calib")
            obj.info("Lattice calibration saved as '%s' and '%s'.", filename, most_recent_filename)
        end
        
        % Track the lattice phase over frames
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
                    "sites", SiteGrid.prepareSite('Hex', 'latr', 20))
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
            disp@LatProcessor(obj)
            for c = string(fields(obj.LatCalib))'
                disp(obj.LatCalib.(c))
            end
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@DataProcessor(obj)
            for i = 1: length(obj.InitCameraName)
                camera = obj.InitCameraName(i);
                if ~isfield(obj.LatCalib, camera)
                    if isfield(obj.Signal, camera)
                        pixel_size = obj.Signal.(camera).Config.PixelSize;
                    else
                        obj.error('Unable to find pixel size for camera %s, please check data config.', camera)
                    end
                    obj.LatCalib.(camera) = Lattice(camera, pixel_size, 'verbose', true);
                else
                    obj.info('Found calibration for %s in loaded LatCalib file.', camera)
                end
            end
            obj.process()
        end
    end

end
