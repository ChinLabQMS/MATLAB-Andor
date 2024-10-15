classdef Replayer < BaseAnalyzer

    properties (SetAccess = immutable, Hidden)
        LayoutManager
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected, Hidden)
        AcquisitionConfig
        DataManager
        StatManager
        CameraManager
        CurrentIndex
    end

    methods
        function obj = Replayer(preprocessor, analyzer, layouts, config)
            arguments
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer(preprocessor)
                layouts = []
                config (1, 1) ReplayerConfig = ReplayerConfig()
            end
            obj@BaseAnalyzer(config)
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
            obj.StatManager.add(analysis, "verbose", options.verbose_level > 3);
            if ~isempty(obj.LayoutManager)
                Live = struct('Raw', raw, 'Signal', signal, ...
                          'Background', background, 'Analysis', analysis, ...
                          'Info', struct('RunNumber', index, ...
                                         'Lattice', obj.Analyzer.Lattice));
                obj.LayoutManager.update(Live, 'verbose', options.verbose_level > 1)
            end
            if options.verbose_level > 0
                obj.info("Sequence completed in %.3f s.\n", toc(timer))
            end
        end
    end

    methods (Access = protected)
        function label = getStatusLabel(obj)
            label = sprintf("%s(Index: %d)", class(obj), obj.CurrentIndex);
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            [obj.DataManager, obj.AcquisitionConfig, obj.CameraManager] = DataManager.struct2obj( ...
                load(obj.Config.DataPath, "Data").Data, "test_mode", obj.Config.TestMode); %#ok<PROP>
            obj.StatManager = StatManager(obj.AcquisitionConfig); %#ok<CPROP>
            obj.StatManager.init()
            obj.CurrentIndex = 0;
            obj.info("Dataset loaded from\n\t[%s].", obj.Config.DataPath)
        end
    end

end
