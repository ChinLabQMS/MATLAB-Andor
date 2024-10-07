classdef BaseStorage < BaseObject
    % BASESTORAGE Base class for storage objects. 
    % This class is used to store data/analysis results, providing a common
    % interface for saving/loading data and exporting to other formats, as well
    % as for checking the current index and memory usage of the storage object.
    % Only the properties that are storing data should be visible to the user.

    properties (SetAccess = immutable)
        AcquisitionConfig (1, 1) AcquisitionConfig
    end

    properties (SetAccess = protected)
        CurrentIndex = 0
    end

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods
        function obj = BaseStorage(config)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
            end
            obj.AcquisitionConfig = config;
        end

        function s = struct(obj, options)
            arguments
                obj
                options.check_incomplete = true
                options.completed_only = true
            end
            if options.check_incomplete && (obj.CurrentIndex < obj.AcquisitionConfig.NumAcquisitions)
                if options.completed_only
                    obj.warn('Incomplete data, only %d of %d acquisitions. Save completed only.', obj.CurrentIndex, obj.AcquisitionConfig.NumAcquisitions)
                else
                    obj.warn('Incomplete data, only %d of %d acquisitions.', obj.CurrentIndex, obj.AcquisitionConfig.NumAcquisitions)
                end
            end
            s = struct('AcquisitionConfig', obj.AcquisitionConfig.struct());
            for camera = obj.getPropList()
                if isempty(obj.(camera))
                    continue
                end
                s.(camera) = obj.(camera);
                % Remove the data that is not yet acquired.
                if options.completed_only && (obj.CurrentIndex < obj.AcquisitionConfig.NumAcquisitions)
                    for label = string(fields(s.(camera)))'
                        if class(s.(camera).(label)) == "table"
                            s.(camera).(label) = s.(camera).(label)(1:obj.CurrentIndex, :);
                        elseif isnumeric(s.(camera).(label))
                            s.(camera).(label) = s.(camera).(label)(:, :, 1:obj.CurrentIndex);
                        end
                    end
                end
            end
        end
        
        function usage = get.MemoryUsage(obj)
            s = obj.struct("check_incomplete", false, "completed_only", false); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end
    end

    methods (Access = protected)
        function cameras = getPropList(obj)
            cameras = getPropList@BaseObject(obj, 'excluded', ["CurrentIndex", "AcquisitionConfig"]);
        end
    end

end
