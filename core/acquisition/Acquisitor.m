classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable, Hidden)
        CameraManager
        Data
        Preprocessor
        Analyzer
        Stat
    end

    properties (SetAccess = protected, Hidden)
        Live (1, 1) struct
    end

    methods
        function obj = Acquisitor(cameras, config, data, preprocessor, analyzer, stat)
            arguments
                cameras (1, 1) CameraManager = CameraManager()
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                data (1, 1) Dataset = Dataset(config, cameras)
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer()
                stat (1, 1) StatResult = StatResult()
            end
            obj@BaseRunner(config);
            obj.CameraManager = cameras;
            obj.Data = data;
            obj.Stat = stat;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        function init(obj)
            obj.CameraManager.init(obj.Config.ActiveCameras);
            obj.Data.init()
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
        end

        function acquire(obj)
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            raw = struct();
            signal = struct();
            background = struct();
            analysis = struct();
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                type = string(sequence_table.Type(i));
                if type == "Start" || type == "Start+Acquire"
                    obj.CameraManager.(camera).startAcquisition()
                end
                if type == "Acquire" || type == "Start+Acquire"
                    step_timer = tic;
                    raw.(camera).(label) = obj.CameraManager.(camera).acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                    fprintf("%s: [%s %s] Aquisition completed in %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                    [signal.(camera).(label), background.(camera).(label)] = obj.Preprocessor.process(raw.(camera).(label), label, obj.Data.(camera).Config);
                end
                if type == "Analysis"
                    % TODO: Implement analysis
                    % step_timer = tic;
                    % data = signal.(camera).(label);
                    % obj.Analyzer.analyze(signal.(camera).(label), obj.Data.(camera).Config)
                    % fprintf("%s: %s %s Analysis elapsed time is %.3f s.\n", obj.CurrentLabel, char(sequence_table.Camera(i)), label, toc(step_timer))
                end
            end
            obj.Data.add(raw);
            % obj.Stat.add(analysis);
            obj.Live = struct('Raw', raw, 'Signal', signal, 'Background', background, 'Analysis', analysis);
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
