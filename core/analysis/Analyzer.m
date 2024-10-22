classdef Analyzer < BaseProcessor

    properties (SetAccess = protected)
        LatCalib = struct()
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

        function res = analyze(obj, signal, processes, options, options2)
            arguments
                obj
                signal (:, :) double
                processes (1, 1) struct
                options.camera (1, 1) string
                options.label (1, 1) string
                options.config (1, 1) {mustBeA(options.config, ["struct", "BaseObject"])}
                options2.verbose (1, 1) logical = false
            end
            timer = tic;
            res = struct();
            options.lattice = obj.LatCalib;
            for p = string(fields(processes))'
                res = processes.(p).Func(res, signal, options, processes.(p).Args{:});
            end
            if options2.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", options.camera, options.label, toc(timer))
            end
        end

        function analysis = analyzeSingleData(obj, data)
        end

        function analysis = analyzeData(obj, data)
        end
    end

    methods (Access = protected, Hidden)
        function applyConfig(obj)
            obj.LatCalib = load(obj.Config.LatCalibFilePath);
            obj.info("Lattice calibration file loaded.")
        end
    end

end
