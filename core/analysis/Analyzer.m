classdef Analyzer < CombinedProcessor
    %ANALYZER Live analyzer

    properties (SetAccess = immutable)
        CounterAndor19330
        CounterAndor19331
    end
    
    methods
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
                func = p{1}; % Analysis function to invoke
                args = p{2}; % Parameters to send to the function
                func(live, info, args{:})
            end
            if options.verbose
                obj.info("[%s %s] Analysis completed in %.3f s.", info.camera, info.label, toc(timer))
            end
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@CombinedProcessor(obj)
        end

        function analysis = analyzeSingleLabel(obj, signal, info, options)
        end

        function analysis = analyzeSingleData(obj, data, options)
        end

        function analysis = analyzeData(obj, data, options)
        end
    end

end
