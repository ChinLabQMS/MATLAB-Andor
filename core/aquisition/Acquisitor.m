classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable, Hidden)
        Cameras
        Preprocessor
        Data
    end

    properties (SetAccess = protected, Hidden)
        NewImages (1, 1) struct
    end

    methods
        function obj = Acquisitor(config, cameras, preprocessor, data)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) Cameras = Cameras()
                preprocessor (1, 1) Preprocessor = Preprocessor()
                data (1, 1) Dataset = Dataset(config, cameras)
            end
            obj@BaseRunner(config);
            obj.Cameras = cameras;
            obj.Preprocessor = preprocessor;
            obj.Data = data;
        end

        function init(obj)
            obj.initCameras()
            obj.Data.init()
        end

        function initCameras(obj)
            obj.Cameras.init(obj.Config.ActiveCameras);
        end

        function config(obj, varargin)
            config@BaseObject(obj, varargin{:})
            obj.Data.init()
        end

        function acquire(obj)
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            new_images = struct();
            processed_images = struct();
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                type = string(sequence_table.Type(i));
                if ~isfield(new_images, camera)
                    new_images.(camera) = struct();
                    processed_images.(camera) = struct();
                end
                if type == "Start" || type == "Start+Acquire"
                    obj.Cameras.(camera).startAcquisition()
                end
                if type == "Acquire" || type == "Start+Acquire"
                    step_timer = tic;
                    new_images.(camera).(label) = obj.Cameras.(camera).acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                    fprintf("%s: %s %s Aquisition elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                    % TODO: Implement preprocessing
                    processed_images.(camera).(label) = new_images.(camera).(label);
                end
                if type == "Analysis"
                    % TODO: Implement analysis
                    step_timer = tic;
                    analysis_note = sequence_table.Note(i);
                    data = processed_images.(camera).(label);
                    % fprintf("%s: %s %s Analysis elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                end
            end
            obj.Data.add(new_images);
            obj.NewImages = new_images;
            fprintf("%s: Sequence completed in %.3f s.\n", obj.CurrentLabel, toc(timer))
        end

        function run(obj)
            obj.init()
            for i = 1:obj.Config.NumAcquisitions
                obj.acquire();
            end
        end
    end

end
