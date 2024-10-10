classdef LatCaliber < BaseRunner
    
    properties (SetAccess = protected)
        Signal
        Stat
        Lattice
    end

    properties (SetAccess = immutable)
        Preprocessor
    end
    
    methods
        function obj = LatCaliber(config, preprocessor)
            arguments
                config (1, 1) LatCalibConfig = LatCalibConfig()
                preprocessor (1, 1) Preprocessor = Preprocessor()
            end
            obj@BaseRunner(config)
            obj.Preprocessor = preprocessor;
        end

        function init(obj)
            obj.Preprocessor.init()
            data = load(obj.Config.DataPath).Data;
            obj.Signal = obj.Preprocessor.processData(data);
            obj.info("Processed Signal loaded for lattice calibration.")

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
            % If provided a path to calibration file, use it
            if ~isempty(obj.Config.LatCalibFilePath)
                obj.Lattice = load(obj.Config.LatCalibFilePath);
            end
            obj.info("Finish processing images.")
        end

        function plot(obj, camera)
            s = obj.Stat.(camera);
            if ~isfield(s, "FFTPattern")
                obj.error("Please process images first.")
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
                "plot_diagnostic", true, ...
                "R_fit", obj.Config.CalibV_RFit, ...
                "binarize_thres", obj.Config.CalibR_BinarizeThres, ...
                "outlier_thres", obj.Config.CalibR_OutlierThres);
            disp(Lat)
        end

        function recalibrate(obj)
            for camera = obj.Config.CameraList
                if ~isempty(obj.Lattice.(camera).K) && isfield(obj.Stat.(camera), "FFTPattern")
                    obj.calibrate(camera)
                else
                    obj.warn("Unable to recalibrate camera %s, please provide initial calibration first.", camera)
                end
            end
        end

        function save(obj)
            for camera = obj.Config.CameraList
                if ~isfield(obj.Lattice, camera)
                    obj.warn("Camera %s is not calibrated.", camera)
                end
            end
            Lat = obj.Lattice;
            Lat.Config = obj.Config;
            save(sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd")), "-struct", "Lat")
        end
    end

end
