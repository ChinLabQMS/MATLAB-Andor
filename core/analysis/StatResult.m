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

        function add(obj, new, options)
            arguments
                obj 
                new (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            obj.CurrentIndex = obj.CurrentIndex + 1;
            for camera = string(fields(new))'
                for label = string(fields(new.(camera)))'
                    new_table = struct2table(new.(camera).(label));
                    if obj.CurrentIndex > size(obj.(camera).(label), 1)
                        obj.(camera).(label) = circshift(obj.(camera).(label), -1, 1);
                        obj.(camera).(label)(end, :) = new_table;
                    else
                        obj.(camera).(label)(obj.CurrentIndex, :) = new_table;
                    end
                end
            end
            if options.verbose
                fprintf("%s: New analysis added to %s in %.3f s.\n", obj.CurrentLabel, class(obj), toc(timer))
            end
        end

    end

end
