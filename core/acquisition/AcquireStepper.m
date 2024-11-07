classdef AcquireStepper < BaseStepper

    methods
        function run(obj)
            [obj.Sequencer.Live.Raw.(obj.CameraName).(obj.ImageLabel), status] = ...
                obj.Sequencer.CameraManager.(obj.CameraName).acquire(obj.RunParams{:});
            obj.Sequencer.Live.BadFrameDetected = obj.Sequencer.Live.BadFrameDetected && status;
        end
    end
    
end
