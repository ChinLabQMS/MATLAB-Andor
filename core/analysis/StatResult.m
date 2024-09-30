classdef StatResult < BaseStorage

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    methods
        function obj = StatResult(config)
            obj@BaseStorage(config)
        end

        function init(obj)
            obj.CurrentIndex = 0;
            sequence = obj.AcquisitionConfig.ActiveAnalysis;
            for i = 1:height(sequence)
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                note = sequence.Note(i);
                num_stat = obj.AcquisitionConfig.NumStatistics;
                [processes, out_vars, out_data, num_out] = parseAnalysisOutput(note);
                if ~isempty(processes) && num_out > 0
                    obj.(camera).(label) = table('Size', [num_stat, length(out_vars) + length(out_data)], ...
                                                 'VariableTypes', [repmat("doublenan", 1, length(out_vars)), ...
                                                                   repmat("cell", 1, length(out_data))], ...
                                                 'VariableNames', [out_vars, out_data]);
                end
            end
            fprintf("%s: %s initialized, total memory is %g MB.\n", obj.CurrentLabel, class(obj), obj.MemoryUsage)
        end

        function add(obj, new_analysis, options)
            arguments
                obj 
                new_analysis (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            for field = obj.PropList
                if isempty(obj.(field))
                    continue
                end
                for label = string(fields(obj.(field))')
                    new = struct2table(new_analysis.(field).(label));
                    if obj.CurrentIndex > size(obj.(field).(label), 1)
                        obj.(field).(label) = circshift(obj.(field).(label), -1, 1);
                        obj.(field).(label)(end, :) = new;
                    else
                        obj.(field).(label)(obj.CurrentIndex, :) = new;
                    end
                end
            end
            if options.verbose
                fprintf("%s: New analysis added to %s in %.3f s.\n", obj.CurrentLabel, class(obj), toc(timer))
            end
        end

    end

end
