classdef DataManager < BaseStorage
    % DATAMANAGER Class for storing acquired data.

    methods
        function obj = DataManager(varargin)
            obj@BaseStorage(varargin{:})
        end
    end

    methods (Access = protected, Hidden)
        function data = removeIncomplete(obj, data)
            data = data(:, :, 1:obj.CurrentIndex);
        end

        function initMaxIndex(obj)
            obj.MaxIndex = obj.AcquisitionConfig.NumAcquisitions;
        end

        function initAnalysisStorage(~, ~, ~)
        end

        function initAcquisitionStorage(obj, camera, label)
            if obj.(camera).Config.MaxPixelValue <= 65535
                obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, ...
                    obj.(camera).Config.YPixels, obj.MaxIndex, "uint16");
            else
                obj.error("Unsupported pixel value range for camera %s.", camera)
            end
        end

        function shift(obj, camera, label)
            obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
        end

        function addNew(obj, new, camera, label)
            index = min(obj.MaxIndex, obj.CurrentIndex);
            obj.(camera).(label)(:, :, index) = new;
        end
    end

    methods (Static)
        function [obj, acq_config, cameras] = struct2obj(data, varargin)
            [obj, acq_config, cameras] = BaseStorage.struct2obj(data, varargin{:}, 'class_name', 'DataManager');
        end
    end

end
