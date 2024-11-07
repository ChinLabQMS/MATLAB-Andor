classdef AcquireStepper < BaseStepper

    methods
        function run(obj, verbose)
            args = [{"label", obj.ImageLabel, "verbose", verbose}, obj.RunParams];
            obj.Sequencer.Live.Raw.(obj.CameraName).(obj.ImageLabel) = ...
                obj.Sequencer.CameraManager.(obj.CameraName).acquire(args{:});
        end
    end

end
