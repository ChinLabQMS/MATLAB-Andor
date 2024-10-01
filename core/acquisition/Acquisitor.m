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
        function obj = Acquisitor(cameras, config, data, stat, preprocessor, analyzer)
            arguments
                cameras (1, 1) CameraManager = CameraManager()
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                data (1, 1) Dataset = Dataset(config, cameras)
                stat (1, 1) StatResult = StatResult(config)
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer()
            end
            obj@BaseRunner(config);
            obj.CameraManager = cameras;
            obj.Data = data;
            obj.Stat = stat;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        function init(obj)
            obj.CameraManager.init(obj.Config.ActiveCameras)
            obj.Data.init()
            obj.Stat.init()
            obj.Preprocessor.init()
            obj.Analyzer.init()
        end

        function acquire(obj, options)
            arguments
                obj
                options.verbose_level (1, 1) double = 1
            end
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            raw = struct();
            signal = struct();
            background = struct();
            analysis = struct();
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                note = string(sequence_table.Note(i));
                type = string(sequence_table.Type(i));
                config = obj.Data.(camera).Config;
                if type == "Start" || type == "Start+Acquire"
                    obj.CameraManager.(camera).startAcquisition( ...
                        "verbose", options.verbose_level > 2)
                end
                if type == "Acquire" || type == "Start+Acquire"
                    raw.(camera).(label) = obj.CameraManager.(camera).acquire( ...
                        'refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout, ...
                        'label', label, 'verbose', options.verbose_level > 1);

                    [signal.(camera).(label), background.(camera).(label)] = obj.Preprocessor.process( ...
                        raw.(camera).(label), label, config, ...
                        "verbose", options.verbose_level > 1);
                end
                if type == "Analysis" && note ~= ""
                    analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        signal.(camera).(label), label, config, ...
                        "verbose", options.verbose_level > 1);
                end
            end
            obj.Data.add(raw, "verbose", options.verbose_level > 1);
            obj.Stat.add(analysis, "verbose", options.verbose_level > 2);
            obj.Live = struct('Raw', raw, 'Signal', signal, 'Background', background, 'Analysis', analysis);
            if options.verbose_level > 0
                fprintf("%s: Sequence completed in %.3f s.\n\n", obj.CurrentLabel, toc(timer))
            end
        end

        function run(obj)
            obj.init()
            for i = 1:obj.Config.NumAcquisitions
                obj.acquire();
            end
        end

        function label = getStatusLabel(obj)
            label = obj.Data.getStatusLabel();
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
