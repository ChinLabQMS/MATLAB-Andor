classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable)
        Cameras
        Data
    end

    methods
        function obj = Acquisitor(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) Cameras = Cameras()
            end
            obj@BaseRunner(config);
            obj.Cameras = cameras;
            obj.Data = Dataset(obj.Config, obj.Cameras);
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

        function vargout = acquire(obj)
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            new_images = struct();
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                type = string(sequence_table.Type(i));
                if ~isfield(new_images, camera)
                    new_images.(camera) = struct();
                end
                if type == "Start" || type == "Start+Acquire"
                    obj.Cameras.(camera).startAcquisition()
                end
                if type == "Acquire" || type == "Start+Acquire"
                    step_timer = tic;
                    new_images.(camera).(label) = obj.Cameras.(camera).acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                    fprintf("%s: %s %s Aquisition elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                end
                if type == "Analysis"
                    % TODO: Implement analysis
                    step_timer = tic;
                    note = sequence_table.Note(i);
                    data = new_images.(camera).(label);
                    % fprintf("%s: %s %s Analysis elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                end
            end
            obj.Data.add(new_images);
            if nargout > 0
                vargout = new_images;
            end
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
