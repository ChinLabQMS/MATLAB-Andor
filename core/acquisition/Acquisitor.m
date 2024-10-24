classdef Acquisitor < BaseRunner

    properties (SetAccess = immutable)
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
        DataManager
        StatManager
    end

    % Class properties that control the live acquisition behaviors
    properties (Constant)
        Acquire_VerboseStart = false
        Acquire_VerboseAcquire = true
        Acquire_VerbosePreprocess = false
        Acquire_VerboseAnalysis = false
        Acquire_VerboseLayout = true
        Acquire_VerboseStorage = false
        Acquire_Verbose = true
    end

    properties (SetAccess = protected)
        Timer (1, 1) uint64
        RunNumber (1, 1) double = 0
    end

    methods
        function obj = Acquisitor(config, cameras, layouts, ...
                                  preprocessor, analyzer, data, stat)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager()
                layouts = []
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer(preprocessor)
                data (1, 1) DataManager = DataManager(config, cameras)
                stat (1, 1) StatManager = StatManager(config)
            end
            obj@BaseRunner(config);
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.DataManager = data;
            obj.StatManager = stat;
        end

        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.Config.ActiveCameras)
            obj.LayoutManager.init()
            obj.DataManager.init()
            obj.StatManager.init()
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info("Acquisition initialized.\n")
        end

        % Perform single acquisition according to the active sequence
        function acquire(obj, options)
            arguments
                obj
                options.verbose_start = obj.Acquire_VerboseStart
                options.verbose_acquire = obj.Acquire_VerboseAcquire
                options.verbose_preprocess = obj.Acquire_VerbosePreprocess
                options.verbose_analysis = obj.Acquire_VerboseAnalysis
                options.verbose_layout = obj.Acquire_VerboseLayout
                options.verbose_storage = obj.Acquire_VerboseStorage
                options.verbose = obj.Acquire_Verbose
            end
            timer = tic;
            obj.RunNumber = obj.RunNumber + 1;
            sequence_table = obj.Config.ActiveSequence;
            % Raw data, processed data (remove background), analysis
            raw = struct();
            signal = struct();
            background = struct();
            analysis = struct();
            % Check the status of the acquisition
            good = true;
            for i = 1:height(sequence_table)
                type = string(sequence_table.Type(i));
                camera = string(sequence_table.Camera(i));
                label = sequence_table.Label(i);
                config = obj.CameraManager.(camera).Config;
                if type == "Start" || type == "Start+Acquire"
                    obj.CameraManager.(camera).startAcquisition("verbose", options.verbose_start)
                end
                if type == "Acquire" || type == "Start+Acquire"
                    args = obj.Config.AcquisitionParams.(camera).(label);
                    % Acquire raw images
                    [raw.(camera).(label), status] = obj.CameraManager.(camera).acquire( ...
                        'refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout, ...
                        'label', label, 'verbose', options.verbose_acquire, args{:});
                    good = good && (status == "good");
                    % Preprocess raw images
                    [signal.(camera).(label), background.(camera).(label)] = obj.Preprocessor.process( ...
                        raw.(camera).(label), 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_preprocess);
                end
                if type == "Analysis"
                    processes = obj.Config.AnalysisProcesses.(camera).(label);
                    % Generate analysis statistics
                    analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        signal.(camera).(label), 'processes', processes, 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_analysis);
                end
            end
            if ~isempty(obj.LayoutManager)
                Live = struct('Raw', raw, 'Signal', signal, ...
                              'Background', background, 'Analysis', analysis, ...
                              'Info', struct('RunNumber', obj.RunNumber, ...
                                             'Lattice', obj.Analyzer.LatCalib));
                obj.LayoutManager.update(Live, 'verbose', options.verbose_layout)
            end
            if good || ~obj.Config.DropBadFrames
                obj.DataManager.add(raw, "verbose", options.verbose_storage);
                obj.StatManager.add(analysis, "verbose", options.verbose_storage);
            else
                obj.warn("Bad acquisition detected, data dropped.")
            end
            if obj.Config.AbortAtEnd
                obj.CameraManager.abortAcquisition(obj.Config.ActiveCameras)
            end
            if options.verbose
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

    methods (Access = protected, Hidden)
        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(RunNum: %d, Index: %d)", class(obj), obj.RunNumber, obj.DataManager.CurrentIndex);
        end
    end

    methods (Static)
        function [acquisitor, config, cameras] = struct2obj(data_struct, layout, preprocessor, analyzer, options)
            arguments
                data_struct (1, 1) struct
                layout = []
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer()
                options.test_mode (1, 1) logical = false
            end
            [data, config, cameras] = DataManager.struct2obj(data_struct, "test_mode", options.test_mode);
            acquisitor = Acquisitor(config, cameras, layout, preprocessor, analyzer, data);
            acquisitor.info("Loaded from structure.")
        end
    end

end
