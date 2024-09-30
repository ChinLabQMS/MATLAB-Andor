classdef BaseStorage < BaseObject

    properties (SetAccess = protected, Hidden)
        CurrentIndex = 0
    end

    properties (SetAccess = protected, Hidden)
        AcquisitionConfig
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
            end
            if options.check_incomplete && (obj.CurrentIndex < obj.AcquisitionConfig.NumAcquisitions)
                warning('backtrace', 'off')
                warning('%s: Incomplete data, only %d of %d acquisitions.', obj.CurrentLabel, obj.CurrentIndex, obj.AcquisitionConfig.NumAcquisitions)
                warning('backtrace', 'on')
            end
            s = struct('AcquisitionConfig', obj.AcquisitionConfig.struct());
            for field = obj.PropList
                if ~isempty(obj.(field))
                    s.(field) = obj.(field);
                end
            end
        end

        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = class(obj) + ".mat"
            end
            save@BaseRunner(obj, filename, "struct_export", true)
        end
        
        function usage = get.MemoryUsage(obj)
            s = obj.struct("check_incomplete", false); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end

        function label = getStatusLabel(obj)
            label = sprintf(" (CurrentIndex: %d)", obj.CurrentIndex);
        end
    end

end
