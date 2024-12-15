classdef Analyzer < BaseProcessor
    %ANALYZER Live analyzer
    
    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241215.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end
    
    methods
        function set.LatCalibFilePath(obj, path)
            obj.loadLatCalibFile(path)
            obj.LatCalibFilePath = path;
        end

        function analyze(obj, live, info, options)
            arguments
                obj
                live
                info.camera
                info.label
                info.config
                options.processes = {}
                options.verbose = false
            end
            timer = tic;
            for p = options.processes
                func = p{1};
                args = p{2};
                func(live, info, args{:})
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
        function loadLatCalibFile(obj, path)
            obj.checkFilePath(path, 'LatCalib')
            obj.LatCalib = load(path);
            obj.info("Lattice calibration file loaded from '%s'.", path)
        end
    end

end
