classdef DataStorage < BaseStorage
    % DATAMANAGER Class for storing acquired data.

    methods (Access = protected, Hidden)
        function data = removeIncomplete(obj, data)
            data = data(:, :, 1:obj.CurrentIndex);
        end

        function initMaxIndex(obj)
            obj.MaxIndex = obj.AcquisitionConfig.NumAcquisitions;
        end

        function initAnalysisStorage(~, ~, ~)
        end

        function initAcquisitionStorage(obj, camera, labels)
            if obj.(camera).Config.MaxPixelValue <= 65535
                for label = labels
                    obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, ...
                        obj.(camera).Config.YPixels, obj.MaxIndex, "uint16");
                end
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

end
