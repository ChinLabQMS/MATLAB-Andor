classdef ReplayAcquireStepper < BaseStepper
    
    methods
        function run(obj, ~)
            obj.Sequencer.Live.Raw.(obj.CameraName).(obj.ImageLabel) = ...
                obj.Sequencer.DataStorage.(obj.CameraName).(obj.ImageLabel)(:, :, obj.Sequencer.CurrentIndex);
        end
    end

end
