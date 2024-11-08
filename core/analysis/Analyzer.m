classdef Analyzer < BaseProcessor
    %ANALYZER Live analyzer
    
    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241105.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end

    properties (Constant)
        Analyze_Verbose = false
    end
    
    methods
        function set.LatCalibFilePath(obj, path)
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end

        function res = analyze(obj, live, info, options)
            arguments
                obj
                live
                info.camera
                info.label
                info.config
                options.processes = {}
                options.verbose = obj.Analyze_Verbose
            end
            timer = tic;
            res = struct();
            info.lattice = obj.LatCalib;
            for i = 1: length(options.processes)
                func = options.processes{i}{1};
                args = options.processes{i}(2: end);
                res = func(res, live, info, args{:});
            end
            if options.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", info.camera, info.label, toc(timer))
            end
        end
    end

    methods (Access = protected)
        function analysis = analyzeSingleLabel(obj, signal, info, options)
        end

        function analysis = analyzeSingleData(obj, data, options)
        end

        function analysis = analyzeData(obj, data, options)
        end
    end

    methods (Access = protected, Hidden)
        function loadLatCalibFile(obj)
            obj.LatCalib = load(obj.LatCalibFilePath);
            obj.info("Lattice calibration file loaded from '%s'.", obj.LatCalibFilePath)
        end
    end

end
