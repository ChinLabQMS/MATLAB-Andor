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
                
                % Step 1: get mean image and fit centers
                signal = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                s.MeanImage = signal;
                [s.XCenter, s.YCenter, s.XWidth, s.YWidth] = fitCenter2D(signal);
                obj.Stat.(camera) = s;
                
                % Step 2: get FFT
            end
            
        end

        function getPreCalib(obj)

        end
    end

end
