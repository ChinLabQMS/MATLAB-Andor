classdef StatStorage < BaseStorage
    % STATMANAGER Class to store analysis results

    methods (Access = protected, Hidden)
        function data = removeIncomplete(obj, data)
            data = data(1: obj.CurrentIndex, :);
        end

        function initMaxIndex(obj)
            obj.MaxIndex = obj.AcquisitionConfig.NumStatistics;
        end

        function initAnalysisStorage(obj, camera, labels)
            for label = labels
                out_vars = obj.AcquisitionConfig.AnalysisOutVars.(camera).(label);
                out_data = obj.AcquisitionConfig.AnalysisOutData.(camera).(label);
                if length(out_vars) + length(out_data) > 0
                    sz = [obj.MaxIndex, length(out_vars) + length(out_data)];
                    var_types = [repmat("doublenan", 1, length(out_vars)), repmat("cell", 1, length(out_data))];
                    obj.(camera).(label) = table('Size', sz, 'VariableTypes', var_types, 'VariableNames', [out_vars, out_data]);
                end
            end
        end

        function initAcquisitionStorage(~, ~, ~)
        end

        function shift(obj, camera, label)
            obj.(camera).(label) = circshift(obj.(camera).(label), -1, 1);
        end

        function addNew(obj, new, camera, label)
            index = min(obj.MaxIndex, obj.CurrentIndex);
            obj.(camera).(label)(index, :) = struct2table(new);
        end
    end

end