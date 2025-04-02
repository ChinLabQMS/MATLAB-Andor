classdef Analyzer < SiteProcessor
    %ANALYZER Live analyzer
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
end
