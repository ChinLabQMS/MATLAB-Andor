classdef StatStorage < BaseStorage
    % STATMANAGER Class to store analysis results

    methods
        function obj = StatStorage(varargin)
            obj@BaseStorage(varargin{:})
        end
    end

    methods (Access = protected, Hidden)
        function data = removeIncomplete(obj, data)
            data = data(1: obj.CurrentIndex, :);
        end

        function initMaxIndex(obj)
            obj.MaxIndex = obj.AcquisitionConfig.NumStatistics;
        end

        function initAnalysisStorage(obj, camera, label)
            out_vars = obj.AcquisitionConfig.AnalysisOutVars.(camera).(label);
            out_data = obj.AcquisitionConfig.AnalysisOutData.(camera).(label);
            
            if length(out_vars) + length(out_data) > 0
                obj.(camera).(label)(obj.MaxIndex) = struct();
            end
        end

        function initAcquisitionStorage(~, ~, ~)
        end

        function shift(obj, camera, label)
            obj.(camera).(label) = circshift(obj.(camera).(label), -1, 1);
        end

        function addNew(obj, new, camera, label)
            index = min(obj.MaxIndex, obj.CurrentIndex);
            obj.(camera).(label)(index) = new;
        end
    end

end
