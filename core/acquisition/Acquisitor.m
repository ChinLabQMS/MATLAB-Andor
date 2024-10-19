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
        RunNumber = 0
    end

    methods
        function obj = Acquisitor(config, cameras, layouts, ...
                                  preprocessor, analyzer, data, stat)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager()
                layouts = LayoutManager().empty()
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer(preprocessor)
                data (1, 1) DataManager = DataManager(config, cameras)
                stat (1, 1) StatManager = StatManager(config)
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
                options.abort (1, 1) logical = true
                options.drop_bad (1, 1) logical = true
                options.verbose_level (1, 1) double = 1
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
                    [raw.(camera).(label), status] = obj.CameraManager.(camera).acquire( ...
                        'refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout, ...
                        'label', label, 'verbose', options.verbose_level > 1);
                    if status ~= "good"
                        good = false;
                    end
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
            if ~isempty(obj.LayoutManager)
                Live = struct('Raw', raw, 'Signal', signal, ...
                              'Background', background, 'Analysis', analysis, ...
                              'Info', struct('RunNumber', obj.RunNumber, ...
                                             'Lattice', obj.Analyzer.Lattice));
                obj.LayoutManager.update(Live, 'verbose', options.verbose_level > 1)
            end
            if good || ~options.drop_bad
                obj.DataManager.add(raw, "verbose", options.verbose_level > 2);
                obj.StatManager.add(analysis, "verbose", options.verbose_level > 3);
            else
                obj.warn("Bad acquisition detected, data dropped.")
            end
            if options.abort
                obj.CameraManager.abortAcquisition(obj.Config.ActiveCameras)
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

    methods (Access = protected)
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
