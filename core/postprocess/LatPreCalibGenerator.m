classdef LatPreCalibGenerator < BaseRunner
    
    properties (SetAccess = protected)
        Signal
        Lattice
    end

    properties (SetAccess = immutable)
        Preprocessor
    end
    
    methods
        function obj = LatPreCalibGenerator(config, preprocessor)
            arguments
                config (1, 1) LatCalibGeneratorConfig = LatCalibGeneratorConfig()
                preprocessor (1, 1) Preprocessor = Preprocessor()
            end
            obj@BaseRunner(config)
            obj.Preprocessor = preprocessor;
        end

        function init(obj)
            data = load(obj.Config.DataPath).Data;
            obj.Preprocessor.init()
            obj.Signal = obj.Preprocessor.processData(data);
            fprintf("%s: Processed Data loaded for lattice calibration.\n", obj.CurrentLabel)
        end

        function process(obj)
            for i = 1: length(obj.Config.CameraList)
                camera = obj.Config.CameraList(i);
                label = obj.Config.ImageLabel(i);
                fprintf("%s: Processing data for camera %s ...\n", obj.CurrentLabel, camera)
                signal = mean(obj.Signal.(camera).(label), 3);
                
                FFT2 = abs(fftshift(fft2(signal)));
                
                fig = figure();
                imagesc(log(FFT2))
                daspect([1 1 1])
                colorbar
                
                while true
                    peak_init = input('Enter a 3x2 matrix, each row represents the peak location (e.g., [1, 2; 2, 3; 3, 4]): \n');
                    if ~isequal(size(peak_init), [3, 2])
                        warning("%s: Invalid input.", obj.CurrentLabel)
                        continue
                    end

                    figure(fig)
                    hold on
                    h2 = scatter(peak_init(:, 2), peak_init(:, 1), "red");
                    
                    answer = input('Please confirm the peak locations are good, input 0 or 1:\n');
                    if answer == 0
                        h2.delete()
                        continue
                    end

                    [size_x, size_y] = size(FFT2);
                    center_x = floor(size_x / 2);
                    center_y = floor(size_y / 2);
                    obj.Lattice.(camera).K = (peak_init-[center_x, center_y])./size_x;
                    obj.Lattice.(camera).V = (inv(obj.Lattice.(camera).K(1:2,:)))';
                    obj.Lattice.(camera).R = [center_x, center_y];
                    break
                end
                
                fig.delete()
            end
        end
    end

end
