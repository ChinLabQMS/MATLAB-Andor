classdef Analyzer < BaseProcessor
    
    % Configurable properties through config method
    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241002.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end

    properties (SetAccess = immutable)
        Preprocessor
    end
    
    methods
        function obj = Analyzer(preprocessor)
            arguments
                preprocessor = Preprocessor()
            end
            obj@BaseProcessor()
            obj.Preprocessor = preprocessor;
        end

        function res = analyze(obj, signal, info, options)
            arguments
                obj
                signal
                info.processes
                info.camera
                info.label
                info.config
                options.verbose = false
            end
            timer = tic;
            res = struct();
            info.lattice = obj.LatCalib;
            for p = string(fields(info.processes))'
                res = info.processes.(p).Func(res, signal, info, info.processes.(p).Args{:});
            end
            if options.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", info.camera, info.label, toc(timer))
            end
        end

        function analysis = analyzeSingleData(obj, data)
        end

        function analysis = analyzeData(obj, data)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.LatCalib = load(obj.LatCalibFilePath);
            obj.info("Lattice calibration file loaded.")
        end
    end

end
