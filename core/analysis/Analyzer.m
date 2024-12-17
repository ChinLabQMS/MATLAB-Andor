classdef Analyzer < LatProcessor & PSFProcessor
    %ANALYZER Live analyzer
    
    methods
        function obj = Analyzer(varargin)
            obj@LatProcessor('reset_fields', false, 'init', false)
            obj@PSFProcessor(varargin{:}, 'reset_fields', true, 'init', true)
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

    methods (Access = protected, Hidden)
        function init(obj)
            init@LatProcessor(obj)
            init@PSFProcessor(obj)
        end

        function analysis = analyzeSingleLabel(obj, signal, info, options)
        end

        function analysis = analyzeSingleData(obj, data, options)
        end

        function analysis = analyzeData(obj, data, options)
        end
    end

end
