classdef Analyzer < BaseRunner

    properties (SetAccess = protected)
        Lattice
    end
    
    methods
        function obj = Analyzer(config)
            arguments
                config (1, 1) AnalysisConfig = AnalysisConfig()
            end
            obj@BaseRunner(config)
        end

        function init(obj)
            obj.Lattice = load(obj.Config.LatCalibFilePath);
            obj.info("Lattice calibration loaded.")
        end

        function res = analyze(obj, signal, label, config, options)
            arguments
                obj
                signal (:, :) double
                label (1, 1) string
                config (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            res = struct();
            processes = parseAnalysisOutput(config.AnalysisNote.(label));
            for p = processes
                res = feval(AnalysisRegistry.(p).FuncName, ...
                            obj, res, signal, label, config);
            end
            if options.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", config.CameraName, label, toc(timer))
            end
        end

        function analysis = analyzeData(obj, data)
        end
    end

    methods (Access = protected)
        function res = fitCenter(~, res, signal, ~, config)
            signal = getSignalSum(signal, getNumFrames(config));
            [res.XCenter, res.YCenter, res.XWidth, res.YWidth] = fitCenter2D(signal);
        end
        
        function res = fitGauss(~, res, signal, ~, ~)
            f = fitGauss2D(signal);
            res.GaussX = f.x0;
            res.GaussY = f.y0;
            res.GaussXWid = f.s1;
            res.GaussYWid = f.s2;
        end

        function res = calibLatR(obj, res, signal, ~, config)
            camera = config.CameraName;
            signal = getSignalSum(signal, getNumFrames(config));
            Lat = obj.Lattice.(camera);
            [signal, x_range, y_range] = prepareBox(signal, Lat.R, obj.Config.LatCalibCroppedR);
            Lat.calibrateR(signal, x_range, y_range)
            res.LatX = obj.Lattice.(camera).R(1);
            res.LatY = obj.Lattice.(camera).R(2);
        end
    end

end
