classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable)
        CameraManager
        LayoutManager
        DataManager
        StatManager
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected)
        Timer (1, 1) uint64
    end

    methods
        function obj = Acquisitor(config, cameras, layouts, ...
                                  data, stat, preprocessor, analyzer)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager()
                layouts = LayoutManager().empty()
                data (1, 1) DataManager = DataManager(config, cameras)
                stat (1, 1) StatManager = StatManager(config)
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer()
            end
            obj@BaseRunner(config);
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.DataManager = data;
            obj.StatManager = stat;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.Config.ActiveCameras)
            obj.DataManager.init()
            obj.StatManager.init()
            obj.Timer = tic;
            obj.info("Acquisition initialized.\n")
        end

        % Perform single acquisition according to the active sequence
        function acquire(obj, options)
            arguments
                obj
                options.verbose_level (1, 1) double = 1
            end
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                type = string(sequence_table.Type(i));
                config = obj.DataManager.(camera).Config;
                if type == "Start" || type == "Start+Acquire"
                    obj.CameraManager.(camera).startAcquisition( ...
                        "verbose", options.verbose_level > 3)
                end
                if type == "Acquire" || type == "Start+Acquire"
                    % Acquire raw images
                    raw.(camera).(label) = obj.CameraManager.(camera).acquire( ...
                        'refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout, ...
                        'label', label, 'verbose', options.verbose_level > 1);
                    % Preprocess raw images
                    [signal.(camera).(label), background.(camera).(label)] = obj.Preprocessor.process( ...
                        raw.(camera).(label), label, config, ...
                        "verbose", options.verbose_level > 2);
                end
                if type == "Analysis"
                    % Generate analysis statistics
                    analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        signal.(camera).(label), label, config, ...
                        "verbose", options.verbose_level > 2);
                end
            end
            obj.DataManager.add(raw, "verbose", options.verbose_level > 2);
            obj.StatManager.add(analysis, "verbose", options.verbose_level > 3);
            Live = struct('Raw', raw, 'Signal', signal, 'Background', background, ...
                          'Analysis', analysis, ...
                          'Info', struct('RunNumber', obj.DataManager.CurrentIndex, ...
                                         'Lattice', obj.Analyzer.Lattice));
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(Live, 'verbose', options.verbose_level > 1)
            end
            if options.verbose_level > 0
                obj.info("Sequence completed in %.3f s.\n", toc(timer))
            end
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
            [data, config, cameras] = DataManager.struct2obj(data_struct, "test_mode", options.test_mode);
            obj = Acquisitor(config, cameras, [], data);
            obj.info("Loaded from structure.")
        end
    end

end
