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

        function process(obj)
            for i = 1: length(obj.Config.CameraList)
                camera = obj.Config.CameraList(i);
                label = obj.Config.ImageLabel(i);
                obj.info("Processing data for camera %s ...", camera)
                
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);
                
                [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];

                obj.Stat.(camera) = s;
                obj.Lattice.(camera) = Lattice(camera); %#ok<CPROP>
            end
            obj.info("Finish processing images.")
            % If provided a path to calibration file, use it
            if ~isempty(obj.Config.LatCalibFilePath)
                obj.Lattice = load(obj.Config.LatCalibFilePath);
                obj.info("Pre-calibration loaded from [%s].", obj.Config.LatCalibFilePath)
            end
        end

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

        function calibrate(obj, camera, peak_init)
            arguments
                obj
                camera
                peak_init = obj.Lattice.(camera).convert2FFTPeak(size(obj.Stat.(camera).FFTPattern))
            end
            Lat = obj.Lattice.(camera);
            FFT = obj.Stat.(camera).FFTPattern;
            obj.Stat.(camera).PeakInit = peak_init;
            Lat.init(obj.Stat.(camera).Center, size(FFT), peak_init)
            disp(Lat)

            obj.Stat.(camera).PeakFinal = Lat.calibrateV( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnosticV", true, "plot_diagnosticR", true);
            disp(Lat)
        end

        function recalibrate(obj)
            if isempty(obj.Signal)
                obj.process()
            end
            for camera = obj.Config.CameraList
                if ~isempty(obj.Lattice.(camera).K) && isfield(obj.Stat.(camera), "FFTPattern")
                    obj.calibrate(camera)
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
            obj.info("Processed Signal loaded for lattice calibration.")
        end
    end

end
