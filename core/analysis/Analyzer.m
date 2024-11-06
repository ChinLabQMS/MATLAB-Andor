classdef Analyzer < BaseProcessor
    %ANALYZER Live analyzer
    
    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241105.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end
    
    methods
        function set.LatCalibFilePath(obj, path)
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end

        function res = analyze(obj, signal, processes, info, options)
            arguments
                obj
                signal
                processes = {}
                info.camera
                info.label
                info.config
                options.verbose = false
            end
            timer = tic;
            res = struct();
            info.lattice = obj.LatCalib;
            for i = 1: length(processes)
                func = processes{i}{1};
                args = processes{i}(2: end);
                res = func(res, signal, info, args{:});
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
            obj.info("Lattice calibration file loaded.")
        end
    end

end
