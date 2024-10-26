classdef LatCaliberator < BaseProcessor
    %LATCALIBERATOR Calibrator for 
    % 1. Getting initial lattice calibration
    % 2. Re-calibrate to a different dataset
    % 3. Analyze calibration drifts

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241002.mat"
        DataPath = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
    end

    properties (Constant)
        CalibR_PlotDiagnostic = true
        CalibV_PlotDiagnostic = true
        CalibO_PlotDiagnostic = true
        CalibO_Camera = "Andor19331"
        CalibO_Camera2 = "Andor19330"
        CalibO_Label = "Image"
        CalibO_Label2 = "Image"
        CalibO_SignalIndex = 1
        CalibO_Sites = Lattice.prepareSite('hex', 'latr', 5)
        CalibO_Verbose = true
        Recalib_CalibO = false
        TrackCalib_CalibOFirst = true
        TrackCalib_CalibOEnd = true
    end
    
    properties (SetAccess = protected)
        Signal
        Stat
        LatCalib
    end
    
    methods
        function obj = LatCaliberator(varargin)
            obj@BaseProcessor(varargin{:})
        end
        
        % Generate FFT patterns for lattice calibration
        function process(obj)
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
                if isempty(obj.LatCalibFilePath)
                    obj.LatCalib.(camera) = Lattice(camera);
                    obj.info("Lattice object created for camera %s.", camera)
                end
            end
            obj.info("Finish processing images.")
        end

        % Plot FFT pattern of images acquired by specified camera
        function plot(obj, camera)
            s = obj.Stat.(camera);
            if ~isfield(s, "FFTPattern")
                obj.error("Please process images first to generate FFT Patterns.")
            end
            figure
            imagesc2(log(s.FFTPattern), 'title', camera)
            if ~isempty(obj.LatCalib.(camera).K)
                peak_pos = obj.LatCalib.(camera).convert2FFTPeak(size(s.FFTPattern));
                viscircles(peak_pos(:, 2:-1:1), 7, ...
                    "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
            end
        end
        
        % Calibrate the lattice vector from a single camera
        function calibrate(obj, camera, center, peak_init, opt1)
            arguments
                obj
                camera
                center = []
                peak_init = obj.LatCalib.(camera).convert2FFTPeak(size(obj.Stat.(camera).FFTPattern))
                opt1.plot_diagnosticR = obj.CalibR_PlotDiagnostic
                opt1.plot_diagnosticV = obj.CalibV_PlotDiagnostic
            end
            Lat = obj.LatCalib.(camera);
            FFT = obj.Stat.(camera).FFTPattern;
            obj.Stat.(camera).PeakInit = peak_init;
            if isempty(obj.LatCalibFilePath)
                center = obj.Stat.(camera).Center;
            end
            Lat.init(center, size(FFT), peak_init)
            Lat0 = Lattice.struct2obj(Lat.struct(["K", "V", "R"]), camera + "_previous", "verbose", false);
            obj.Stat.(camera).PeakFinal = Lat.calibrate( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnosticV", opt1.plot_diagnosticV, "plot_diagnosticR", opt1.plot_diagnosticR);
            Lattice.checkDiff(Lat0, Lat)
        end
        
        % Cross-calibrate the lattice origin of camera to match camera2
        function calibrateO(obj, signal_index, opt2)
            arguments
                obj
                signal_index = 1
                opt2.camera = obj.CalibO_Camera
                opt2.camera2 = obj.CalibO_Camera2
                opt2.label = obj.CalibO_Label
                opt2.label2 = obj.CalibO_Label2
                opt2.sites = obj.CalibO_Sites
                opt2.verbose = obj.CalibO_Verbose
                opt2.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if isempty(obj.Stat)
                obj.process()
            end
            signal = getSignalSum(obj.Signal.(opt2.camera).(opt2.label)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(opt2.camera).Config), "first_only", true);
            signal2 = getSignalSum(obj.Signal.(opt2.camera2).(opt2.label2)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(opt2.camera2).Config), "first_only", true);
            [signal, x_range, y_range] = prepareBox(signal, obj.LatCalib.(opt2.camera).R, 2*obj.Stat.(opt2.camera).Width);
            [signal2, x_range2, y_range2] = prepareBox(signal2, obj.LatCalib.(opt2.camera2).R, 2*obj.Stat.(opt2.camera2).Width);
            obj.LatCalib.(opt2.camera).calibrateR(signal, x_range, y_range)
            obj.LatCalib.(opt2.camera2).calibrateR(signal2, x_range2, y_range2)
            obj.LatCalib.(opt2.camera).calibrateO(obj.LatCalib.(opt2.camera2), ...
                signal, signal2, x_range, y_range, x_range2, y_range2, ...
                "sites", opt2.sites, "plot_diagnosticO", opt2.plot_diagnosticO, ...
                "verbose", opt2.verbose, "debug", false)           
        end
        
        % Re-calibrate the lattice vectors
        function recalibrate(obj, opt1, opt2)
            arguments
                obj
                opt1.plot_diagnosticR = obj.CalibR_PlotDiagnostic
                opt1.plot_diagnosticV = obj.CalibV_PlotDiagnostic
                opt2.calibO = obj.Recalib_CalibO
                opt2.plot_diagnosticO = obj.CalibO_PlotDiagnostic
            end
            if isempty(obj.Stat)
                obj.process()
            end
            args1 = namedargs2cell(opt1);
            for camera = obj.CameraList
                if ~isempty(obj.LatCalib.(camera).K) && isfield(obj.Stat.(camera), "FFTPattern")
                    obj.calibrate(camera, args1{:})
                else
                    obj.warn("Unable to recalibrate camera %s, please provide initial calibration first.", camera)
                end
            end
            if opt2.calibO
                obj.calibrateO(1, "plot_diagnostic", opt2.plot_diagnosticO)
            end
        end
        
        % Save the calibration result to file
        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
            end
            for camera = obj.CameraList
                if ~isfield(obj.LatCalib, camera)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            Lat = obj.LatCalib;
            Lat.Config = obj.struct();
            save(filename, "-struct", "Lat")
            obj.info("Lattice calibration saved as [%s].", filename)
        end

        function result = trackCalib(obj, options)
            arguments
                obj
                options.calibO_first = obj.TrackCalib_CalibOFirst
                options.calibO_end = obj.TrackCalib_CalibOEnd
            end
            num_acq = obj.Signal.AcquisitionConfig.NumAcquisitions;
            result(num_acq) = struct();
            obj.recalibrate("calibO", false, "plot_diagnosticO", false, "plot_diagnosticR", false, "plot_diagnosticV", false)
            if options.calibO_first
                obj.calibrateO(1, "plot_diagnosticO", false, "verbose", false)
            end
            for i = 1: num_acq
                for j = 1: length(obj.CameraList)
                    camera = obj.CameraList(j);
                    label = obj.ImageLabel(j);
                    signal = obj.Signal.(camera).(label)(:, :, i);
                    signal = getSignalSum(signal, getNumFrames(obj.Signal.(camera).Config));
                    Lat = obj.LatCalib.(camera);
                    Lat.calibrateR(signal)
                    result(i).(camera) = Lat.R;
                end
            end
            if options.calibO_end
                obj.calibrateO(num_acq, "plot_diagnosticO", false, "verbose", false)
            end
            result = struct2table(result);
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.Signal = Preprocessor().processData(load(obj.DataPath).Data);
            if ~isempty(obj.LatCalibFilePath)
                obj.LatCalib = load(obj.LatCalibFilePath);
                obj.info("Pre-calibration loaded from:\n\t'%s'.", obj.LatCalibFilePath)
            end
        end
    end

end
