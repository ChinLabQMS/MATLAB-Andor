classdef LatPreCalibGenerator < BaseRunner
    
    properties (SetAccess = protected)
        Signal
        Stat
        Lattice
    end

    properties (SetAccess = immutable)
        Preprocessor
    end
    
    methods
        function obj = LatPreCalibGenerator(config, preprocessor)
            arguments
                config (1, 1) LatPreCalibGeneratorConfig = LatPreCalibGeneratorConfig()
                preprocessor (1, 1) Preprocessor = Preprocessor()
            end
            obj@BaseRunner(config)
            obj.Preprocessor = preprocessor;
        end

        function init(obj)
            obj.Preprocessor.init()
            data = load(obj.Config.DataPath).Data;
            obj.Signal = obj.Preprocessor.processData(data);
            fprintf("%s: Processed Signal loaded for lattice calibration.\n", obj.CurrentLabel)

            for i = 1: length(obj.Config.CameraList)
                camera = obj.Config.CameraList(i);
                label = obj.Config.ImageLabel(i);
                fprintf("%s: Processing data for camera %s ...\n", obj.CurrentLabel, camera)
                
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);
                
                [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];

                obj.Stat.(camera) = s;
                obj.Lattice.(camera) = Lattice(camera); %#ok<CPROP>
            end
            fprintf("%s: Finish processing images.\n", obj.CurrentLabel)
        end

        function plot(obj, camera)
            s = obj.Stat.(camera);
            if ~isfield(s, "FFTPattern")
                error("%s: Please process images first.", obj.CurrentLabel)
            end
            figure
            imagesc(log(s.FFTPattern))
            axis image
            title(camera)
            colorbar
        end

        function calibrate(obj, camera, peak_init)
            Lat = obj.Lattice.(camera);
            FFT = obj.Stat.(camera).FFTPattern;
            obj.Stat.(camera).PeakInit = peak_init;
            Lat.init(size(FFT), peak_init, obj.Stat.(camera).Center)
            disp(Lat)

            obj.Stat.(camera).PeakFinal = Lat.calibrateV( ...
                obj.Stat.(camera).FFTImage, obj.Stat.(camera).FFTX, obj.Stat.(camera).FFTY, ...
                "plot_diagnostic", true, "plot_fftpeaks", true);
            disp(Lat)
        end

        function save(obj)
            for camera = obj.Config.CameraList
                if ~isfield(obj.Lattice, camera)
                    warning("%s: Camera %s is not calibrated.", obj.CurrentLabel, camera)
                end
            end
            Lat = obj.Lattice;
            save(sprintf("calibration/LatCalib_%s", datetime("now", "Format","uuuuMMdd")), "-struct", "Lat")
        end
    end

end
