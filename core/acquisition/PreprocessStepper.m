classdef PreprocessStepper < BaseStepper

    methods
        function run(obj)
            [signal, background] = obj.Sequencer.Preprocessor.process( ...
                obj.Sequencer.Live.Raw.(obj.CameraName).(obj.ImageLabel), obj.RunParams{:});
            obj.Sequencer.Live.Signal.(obj.CameraName).(obj.ImageLabel) = signal;
            obj.Sequencer.Live.Background.(obj.CameraName).(obj.ImageLabel) = background;
        end
    end

    methods (Access = protected)
        function params = getDefaultParams(obj)
            params = {"camera", obj.CameraName, ...
                      "label", obj.ImageLabel, ...
                      "config", obj.Sequencer.CameraManager.(obj.CameraName).Config};
        end
    end

end
