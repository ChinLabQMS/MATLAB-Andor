classdef Analyzer < BaseProcessor
    %ANALYZER Live analyzer
    
    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241002.mat"
    end

    properties (SetAccess = protected)
        LatCalib
    end
    
    methods
        function set.LatCalibFilePath(obj, path)
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end

        function res = analyze(obj, signal, info, options)
            arguments
                obj
                signal
                info
                options.verbose = false
            end
            timer = tic;
            assert(all(isfield(info, ["camera", "label", "config", "processor"])))
            res = struct();
            info.lattice = obj.LatCalib;
            for p = string(fields(info.processes))'
                res = info.processes.(p).Func(res, signal, info, info.processes.(p).Args{:});
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
        function init(~)
        end

        function loadLatCalibFile(obj)
            obj.LatCalib = load(obj.LatCalibFilePath);
            obj.info("Lattice calibration file loaded.")
        end
    end

end
