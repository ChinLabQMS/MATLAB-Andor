classdef StartStepper < BaseStepper
        
    methods
        function run(obj, verbose)
            args = [{"label", obj.ImageLabel, "verbose", verbose}, obj.RunParams];
            obj.Sequencer.CameraManager.(obj.CameraName).startAcquisition(args{:})
        end
    end

end
