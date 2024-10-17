classdef LatCaliberator < BaseAnalyzer
    %LATCALIBERATOR Calibrator for initial lattice calibration and recalibration
    
    properties (SetAccess = protected)
        Signal
        Stat
        Lattice
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
                    obj.Lattice.(camera) = Lattice(camera); %#ok<CPROP>
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
            if ~isempty(obj.Lattice.(camera).K)
                peak_pos = obj.Lattice.(camera).convert2FFTPeak(size(s.FFTPattern));
                viscircles(peak_pos(:, 2:-1:1), 7, ...
                    "EnhanceVisibility", false, "Color", "white", "LineWidth", 1);
            end
        end

        function calibrate(obj, camera, peak_init, options)
            arguments
                obj
                camera (1, 1) string
                peak_init (:, 2) double = obj.Lattice.(camera).convert2FFTPeak(size(obj.Stat.(camera).FFTPattern))
                options.plot_diagnosticV (1, 1) logical = true
                options.plot_diagnosticR (1, 1) logical = true
            end
            Lat = obj.Lattice.(camera);
            FFT = obj.Stat.(camera).FFTPattern;
            obj.Stat.(camera).PeakInit = peak_init;
            Lat.init(obj.Stat.(camera).Center, size(FFT), peak_init)
            disp(Lat)  % Display initial lattice calibration
            obj.Stat.(camera).PeakFinal = Lat.calibrateV( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnosticV", options.plot_diagnosticV, "plot_diagnosticR", options.plot_diagnosticR);
            disp(Lat)  % Display final lattice calibration
        end
        
        function calibrateSignal(obj, camera, camera2)

        end

        function recalibrate(obj, options)
            arguments
                obj
                options.plot_diagnosticV (1, 1) logical = true
                options.plot_diagnosticR (1, 1) logical = true
            end
            for camera = obj.Config.CameraList
                if ~isempty(obj.Lattice.(camera).K) && isfield(obj.Stat.(camera), "FFTPattern")
                    obj.calibrate(camera, "plot_diagnosticV", options.plot_diagnosticV, ...
                        "plot_diagnosticR", options.plot_diagnosticR)
                else
                    obj.warn("Unable to recalibrate camera %s, please provide initial calibration first.", camera)
                end
            end
        end

        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd"))
            end
            for camera = obj.Config.CameraList
                if ~isfield(obj.Lattice, camera)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            Lat = obj.Lattice;
            Lat.Config = obj.Config;
            save(filename, "-struct", "Lat")
            obj.info("Lattice calibration saved as [%s].", filename)
        end
    end

    methods (Access = protected)
        function init(obj)
            obj.Signal = Preprocessor().processData(load(obj.Config.DataPath).Data);
            if ~isempty(obj.Config.LatCalibFilePath)
                obj.Lattice = load(obj.Config.LatCalibFilePath);
                obj.info("Pre-calibration loaded from [%s].", obj.Config.LatCalibFilePath)
            end
        end
    end

end
