classdef StatManager < BaseStorage

    properties (SetAccess = protected)
        Andor19330
        Andor19331
        Zelux
    end

    methods
        function obj = StatManager(config)
            obj@BaseStorage(config)
        end

        % Initialize the storage
        function init(obj)
            obj.CurrentIndex = 0;
            sequence = obj.AcquisitionConfig.ActiveAnalysis;
            for camera = obj.getPropList()
                if ~ismember(camera, obj.AcquisitionConfig.ActiveCameras)
                    obj.(camera) = [];
                    continue
                end
            end
            for i = 1:height(sequence)
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                note = sequence.Note(i);
                num_stat = obj.AcquisitionConfig.NumStatistics;
                [~, out_vars, out_data, num_out] = parseAnalysisOutput(note);
                if num_out > 0
                    obj.(camera).(label) = table('Size', [num_stat, length(out_vars) + length(out_data)], ...
                                                 'VariableTypes', [repmat("doublenan", 1, length(out_vars)), ...
                                                                   repmat("cell", 1, length(out_data))], ...
                                                 'VariableNames', [out_vars, out_data]);
                end
            end
            obj.info("Storage initialized, total memory is %g MB.", obj.MemoryUsage)
        end

        % Add new data to the storage
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
                obj.info("New analysis added in %.3f s.", toc(timer))
            end
        end

    end

end
