classdef StartAcquireStepper < BaseStepper

    methods
        function run(obj, verbose)
            args = [{"label", obj.ImageLabel, "verbose", verbose}, obj.RunParams.StartParams];
            obj.Sequencer.CameraManager.(obj.CameraName).startAcquisition(args{:})
            args = [{"label", obj.ImageLabel, "verbose", verbose}, obj.RunParams.AcquireParams];
            obj.Sequencer.Live.Raw.(obj.CameraName).(obj.ImageLabel) = ...
                obj.Sequencer.CameraManager.(obj.CameraName).acquire(args{:});
        end
    end

    methods (Access = protected)
        function params = parseRunParams(obj, note)
            params = obj.parseString2Processes(note, ["Start", "Acquire"], "full_struct", true);
        end
    end

end
