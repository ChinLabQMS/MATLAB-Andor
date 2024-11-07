classdef StartStepper < BaseStepper
        
    methods
        function run(obj)
            obj.Sequencer.CameraManager.(obj.CameraName).startAcquisition(obj.RunParams{:})
        end
    end

end
