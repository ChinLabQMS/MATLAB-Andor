classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable, Hidden)
        Cameras
        Data
        Stat
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected)
        Live (1, 1) struct
    end

    methods
        function obj = Acquisitor(config, cameras, data, stat, preprocessor, analyzer)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) Cameras = Cameras()
                data (1, 1) Dataset = Dataset(config, cameras)
                stat (1, 1) StatResult = StatResult()
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer()                
            end
            obj@BaseRunner(config);
            obj.Cameras = cameras;
            obj.Data = data;
            obj.Stat = stat;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        function init(obj)
            obj.Cameras.init(obj.Config.ActiveCameras);
            obj.Data.init()
            obj.Preprocessor.init()
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            obj.Data.init()
        end

        function acquire(obj)
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            new_images = struct();
            processed_images = struct();
            analysis = struct();
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
                    processed_images.(camera).(label) = obj.Preprocessor.process(new_images.(camera).(label), label, obj.Data.(camera).Config);
                end
                if type == "Analysis"
                    % TODO: Implement analysis
                    % step_timer = tic;
                    % data = processed_images.(camera).(label);
                    % fprintf("%s: %s %s Analysis elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                end
            end
            obj.Data.add(new_images);
            % obj.Stat.add(analysis);
            obj.Live = struct('RawImage', new_images, 'ProcessedImage', processed_images, 'Analysis', analysis);
            fprintf("%s: Sequence completed in %.3f s.\n", obj.CurrentLabel, toc(timer))
        end

        function run(obj)
            obj.init()
            for i = 1:obj.Config.NumAcquisitions
                obj.acquire();
            end
        end
    end

    methods (Static)
        function obj = struct2obj(data_struct, options)
            arguments
                data_struct (1, 1) struct
                options.test_mode (1, 1) logical = false
            end
            [data, config, cameras] = Dataset.struct2obj(data_struct, "test_mode", options.test_mode);
            obj = Acquisitor(config, cameras, data);
            fprintf("%s: %s loaded from structure.\n", obj.CurrentLabel, class(obj))
        end

        function obj = file2obj(filename, varargin)
            if isfile(filename)
                s = load(filename, 'Data');
                obj = Acquisitor.struct2obj(s, varargin{:});
            else
                error("File %s does not exist.", filename)
            end
        end
    end

end
