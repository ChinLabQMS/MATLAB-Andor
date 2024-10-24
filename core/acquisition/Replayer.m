classdef Replayer < BaseProcessor

    properties (SetAccess = immutable, Hidden)
        AcquisitionConfig
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected, Hidden)
        DataManager
        StatManager
        CurrentIndex
    end

    methods
        function obj = Replayer(acq_config, cameras, layouts, ...
                preprocessor, analyzer, config)
            arguments
                acq_config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) CameraManager = CameraManager("test_mode", 1)
                layouts = []
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer(preprocessor)
                config (1, 1) ReplayerConfig = ReplayerConfig()
            end
            obj@BaseProcessor(config)
            obj.AcquisitionConfig = acq_config;
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        function update(obj, index, options)
            arguments
                obj
                index (1, 1) double = 1
                options.verbose_level (1, 1) double = 1
            end
            timer = tic;
            if index <= obj.AcquisitionConfig.NumAcquisitions && index > 0
                obj.CurrentIndex = index;
            else
                obj.CurrentIndex = 1;
            end
            sequence_table = obj.AcquisitionConfig.ActiveSequence;
            for i = 1:height(sequence_table)
                camera = string(sequence_table.Camera(i));
                label = string(sequence_table.Label(i));
                type = string(sequence_table.Type(i));
                config = obj.DataManager.(camera).Config;
                if type == "Acquire" || type == "Start+Acquire"
                    % Pick raw images
                    raw.(camera).(label) = obj.DataManager.(camera).(label)(:, :, index);
                    % Preprocess raw images
                    [signal.(camera).(label), background.(camera).(label)] = obj.Preprocessor.process( ...
                        raw.(camera).(label), 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_level > 2);
                end
                if type == "Analysis"
                    processes = obj.AcquisitionConfig.AnalysisProcesses.(camera).(label);
                    % Generate analysis statistics
                    analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        signal.(camera).(label), processes, 'camera', camera, 'label', label, 'config', config, ...
                        "verbose", options.verbose_level > 2);
                end
            end
            obj.StatManager.add(analysis, "verbose", options.verbose_level > 3);
            if ~isempty(obj.LayoutManager)
                Live = struct('Raw', raw, 'Signal', signal, ...
                              'Background', background, 'Analysis', analysis, ...
                              'Info', struct('RunNumber', index, ...
                                             'Lattice', obj.Analyzer.LatCalib));
                obj.LayoutManager.update(Live, 'verbose', options.verbose_level > 1)
            end
            if options.verbose_level > 0
                obj.info("Sequence completed in %.3f s.\n", toc(timer))
            end
        end
    end

    methods (Access = protected, Hidden)
        % Override the default behavior in BaseProcessor
        function applyConfig(obj)
            obj.DataManager = DataManager.struct2obj( ...
                load(obj.Config.DataPath, "Data").Data, ...
                obj.AcquisitionConfig, ...
                obj.CameraManager, ...
                "test_mode", obj.Config.TestMode); %#ok<PROP>
            obj.StatManager = StatManager(obj.AcquisitionConfig); %#ok<CPROP>
            obj.StatManager.init()
            obj.CurrentIndex = 0;
            obj.info("Dataset loaded from:\n\t'%s'.", obj.Config.DataPath)
        end

        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(Index: %d)", class(obj), obj.CurrentIndex);
        end
    end

end
