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
        end

        function process(obj)
            for i = 1: length(obj.Config.CameraList)
                camera = obj.Config.CameraList(i);
                label = obj.Config.ImageLabel(i);
                fprintf("%s: Processing data for camera %s ...\n", obj.CurrentLabel, camera)
                
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);
                
                s.FFTImage = prepareBox(s.MeanImage, [xc, yc], 2*min(xw, yw));
                s.FFT = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];

                obj.Stat.(camera) = s;
            end
            fprintf("%s: Finish processing images.\n", obj.CurrentLabel)
        end

        function plot(obj, camera)
            s = obj.Stat.(camera);
            if ~isfield(s, "FFT")
                error("%s: Please process images first.", obj.CurrentLabel)
            end
            figure
            imagesc(log(s.FFT))
            axis image
            title(camera)
            colorbar
            if isfield(s, "PeakInit")
                hold on
                viscircles([s.PeakInit(:, 2), s.PeakInit(:, 1)], 7, ...
                    'Color', 'red', 'LineWidth', 1, 'EnhanceVisibility', false);
            end
            if isfield(s, "PeakFinal")
                viscircles([s.PeakFinal(:, 2), s.PeakFinal(:, 1)], 2, ...
                    'Color', 'white', 'LineWidth', 1, 'EnhanceVisibility', false);
            end
        end

        function calibrate(obj, camera, peak_init)
            xy_size = size(obj.Stat.(camera).FFT);
            xy_center = (xy_size+1) / 2;

            obj.Stat.(camera).PeakInit = peak_init;
            obj.Lattice.(camera).K = (peak_init-xy_center)./xy_size;
            obj.Lattice.(camera).V = (inv(obj.Lattice.(camera).K(1:2,:)))';
            obj.Lattice.(camera).R = obj.Stat.(camera).Center;           
            printLatCalibration(obj.Lattice.(camera))

            obj.Lattice.(camera) = calibLatV(obj.Stat.(camera).MeanImage, ...
                obj.Lattice.(camera), ...
                "R_crop", 2*obj.Stat.(camera).Width, ...
                "R_fit", 7);
            obj.Stat.(camera).PeakFinal = xy_size .* obj.Lattice.(camera).K + xy_center;
            printLatCalibration(obj.Lattice.(camera))
        end

        function save(obj)
            
        end
    end

end
