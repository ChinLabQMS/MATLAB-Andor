classdef Acquisitor < BaseObject

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
        Timer
        RunNumber = 0
        Live
    end

    methods
        function obj = Acquisitor(config, cameras, layouts, ...
                                  preprocessor, analyzer, data, stat)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager()
                layouts = []
                preprocessor = Preprocessor()
                analyzer = Analyzer(preprocessor)
                data = DataManager(config, cameras)
                stat = StatManager(config, cameras)
            end
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
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.DataManager.init()
            obj.StatManager.init()
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Acquisition initialized.")
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
            obj.Live = struct('Info', struct('RunNumber', obj.RunNumber, ...
                                         'Lattice', obj.Analyzer.LatCalib), ...
                              'Raw', [], 'Signal', [], 'Background', [], 'Analysis', []);
            sequence_table = obj.Config.ActiveSequence;
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
                    [obj.Live.Raw.(camera).(label), status] = obj.CameraManager.(camera).acquire( ...
                        'refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout, ...
                        'label', label, 'verbose', options.verbose_acquire, args{:});
                    good = good && (status == "good");
                    % Preprocess raw images
                    [obj.Live.Signal.(camera).(label), obj.Live.Background.(camera).(label)] = obj.Preprocessor.process( ...
                        obj.Live.Raw.(camera).(label), 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_preprocess);
                end
                if type == "Analysis"
                    processes = obj.Config.AnalysisProcesses.(camera).(label);
                    % Generate analysis statistics
                    obj.Live.Analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        obj.Live.Signal.(camera).(label), 'processes', processes, 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_analysis);
                end
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj.Live, 'verbose', options.verbose_layout)
            end
            if good || ~obj.Config.DropBadFrames
                obj.DataManager.add(obj.Live.Raw, "verbose", options.verbose_storage);
                obj.StatManager.add(obj.Live.Analysis, "verbose", options.verbose_storage);
            else
                obj.warn("Bad acquisition detected, data dropped.")
            end
            if obj.Config.AbortAtEnd
                obj.CameraManager.abortAcquisition(obj.Config.ActiveCameras)
            end
            if options.verbose
                obj.info2("Sequence completed in %.3f s.", toc(timer))
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
        function [acquisitor, config, cameras] = struct2obj(data, layout, preprocessor, analyzer, options)
            arguments
                data
                layout = []
                preprocessor = Preprocessor()
                analyzer = Analyzer()
                options.test_mode = false
            end
            [data, config, cameras] = DataManager.struct2obj(data, "test_mode", options.test_mode);
            acquisitor = Acquisitor(config, cameras, layout, preprocessor, analyzer, data);
            acquisitor.info("Loaded from structure.")
        end
    end

end
