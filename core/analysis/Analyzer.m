classdef Analyzer < BaseProcessor

    properties (SetAccess = protected)
        Lattice
    end

    properties (SetAccess = immutable)
        Preprocessor
    end
    
    methods
        function obj = Analyzer(preprocessor, config)
            arguments
                preprocessor (1, 1) Preprocessor = Preprocessor()
                config (1, 1) AnalysisConfig = AnalysisConfig()
            end
            obj@BaseProcessor(config)
            obj.Preprocessor = preprocessor;
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
            processes = AnalysisRegistry.parseOutput(config.AnalysisNote.(label));
            for p = string(fields(processes))'
                res = processes.(p).Func(res, obj, signal, label, config, processes.(p).Args{:});
            end
            if options.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", config.CameraName, label, toc(timer))
            end
        end

        function analysis = analyzeData(obj, data)
        end
    end

    methods (Access = protected, Hidden)
        function applyConfig(obj)
            obj.Lattice = load(obj.Config.LatCalibFilePath);
            obj.info("Lattice calibration file loaded.")
        end
    end

end
