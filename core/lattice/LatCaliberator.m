classdef LatCaliberator < BaseAnalyzer
    %LATCALIBERATOR Calibrator for initial lattice calibration and recalibration
    
    properties (SetAccess = protected)
        Signal
        Stat
        LatCalib
    end
    
    methods
        function obj = LatCaliberator(config)
            arguments
                config (1, 1) LatCalibConfig = LatCalibConfig()
            end
            obj@BaseAnalyzer(config)
        end
        
        % Generate FFT patterns for lattice calibration
        function process(obj)
            for i = 1: length(obj.Config.CameraList)
                camera = obj.Config.CameraList(i);
                label = obj.Config.ImageLabel(i);                
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);                
                [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];                
                obj.Stat.(camera) = s;

                if isempty(obj.Config.LatCalibFilePath)
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
            imagesc(log(s.FFTPattern))
            axis image
            title(camera)
            colorbar
            if ~isempty(obj.LatCalib.(camera).K)
                peak_pos = obj.LatCalib.(camera).convert2FFTPeak(size(s.FFTPattern));
                viscircles(peak_pos(:, 2:-1:1), 7, ...
                    "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
            end
        end
        
        % Calibrate the lattice vector from a single camera
        function calibrate(obj, camera, peak_init, options)
            arguments
                obj
                camera (1, 1) string
                peak_init (:, 2) double = obj.LatCalib.(camera).convert2FFTPeak(size(obj.Stat.(camera).FFTPattern))
                options.plot_diagnosticV (1, 1) logical = true
                options.plot_diagnosticR (1, 1) logical = true
            end
            Lat = obj.LatCalib.(camera);
            FFT = obj.Stat.(camera).FFTPattern;
            obj.Stat.(camera).PeakInit = peak_init;
            Lat.init(obj.Stat.(camera).Center, size(FFT), peak_init)
            disp(Lat)  % Display initial lattice calibration
            obj.Stat.(camera).PeakFinal = Lat.calibrateV( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnosticV", options.plot_diagnosticV, "plot_diagnosticR", options.plot_diagnosticR);
            disp(Lat)  % Display final lattice calibration
        end
        
        % Cross-calibrate the lattice origin of camera to match camera2
        function calibrateO(obj, camera, camera2, label, label2, signal_index, options)
            arguments
                obj
                camera (1, 1) string = "Andor19331"
                camera2 (1, 1) string = "Andor19330"
                label (1, 1) string = "Image"
                label2 (1, 1) string = "Image"
                signal_index (1, 1) double = 1
                options.sites (:, 2) double = Lattice.prepareSite("hex", "latr", 20)
                options.verbose (1, 1) logical = false
                options.plot_diagnostic (1, 1) logical = true
            end
            signal = getSignalSum(obj.Signal.(camera).(label)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(camera).Config), "first_only", true);
            signal2 = getSignalSum(obj.Signal.(camera2).(label2)(:, :, signal_index), ...
                getNumFrames(obj.Signal.(camera2).Config), "first_only", true);
            [signal, x_range, y_range] = prepareBox(signal, obj.Stat.(camera).Center, 2 * obj.Stat.(camera).Width);
            [signal2, x_range2, y_range2] = prepareBox(signal2, obj.Stat.(camera2).Center, 2 * obj.Stat.(camera2).Width);
            obj.LatCalib.(camera).calibrateR(signal, x_range, y_range)
            obj.LatCalib.(camera2).calibrateR(signal2, x_range2, y_range2)
            obj.LatCalib.(camera).calibrateO(obj.LatCalib.(camera2), ...
                signal, signal2, x_range, y_range, x_range2, y_range2, ...
                "sites", options.sites, "plot_diagnostic", options.plot_diagnostic, "verbose", options.verbose, "debug", false)
        end
        
        % Re-calibrate the lattice vectors
        function recalibrate(obj, options)
            arguments
                obj
                options.plot_diagnosticV (1, 1) logical = true
                options.plot_diagnosticR (1, 1) logical = true
                options.plot_diagnosticO (1, 1) logical = true
            end
            for camera = obj.Config.CameraList
                if ~isempty(obj.LatCalib.(camera).K) && isfield(obj.Stat.(camera), "FFTPattern")
                    obj.calibrate(camera, "plot_diagnosticV", options.plot_diagnosticV, ...
                        "plot_diagnosticR", options.plot_diagnosticR)
                else
                    obj.warn("Unable to recalibrate camera %s, please provide initial calibration first.", camera)
                end
            end
            obj.calibrateO("plot_diagnostic", options.plot_diagnosticO)
        end
        
        % Save the calibration result to file
        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
            end
            for camera = obj.Config.CameraList
                if ~isfield(obj.LatCalib, camera)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            Lat = obj.LatCalib;
            Lat.Config = obj.Config;
            save(filename, "-struct", "Lat")
            obj.info("Lattice calibration saved as [%s].", filename)
        end
    end

    methods (Access = protected)
        function init(obj)
            obj.Signal = Preprocessor().processData(load(obj.Config.DataPath).Data);
            if ~isempty(obj.Config.LatCalibFilePath)
                obj.LatCalib = load(obj.Config.LatCalibFilePath);
                obj.info("Pre-calibration loaded from [%s].", obj.Config.LatCalibFilePath)
            end
        end
    end

end
