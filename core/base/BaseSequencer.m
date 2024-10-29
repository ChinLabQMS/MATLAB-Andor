classdef BaseSequencer < BaseObject

    properties (SetAccess = immutable)
        AcquisitionConfig
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
        DataManager
        StatManager
    end

    properties (Constant)
        Run_Verbose = true
        Run_VerboseLayout = true
        Run_VerboseData = true
        Run_VerboseStat = false
    end

    properties (SetAccess = protected)
        Timer
        RunNumber = 0
        Live
    end

    methods
        function obj = BaseSequencer(config, cameras, layouts, ...
                preprocessor, analyzer, data, stat)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager()
                layouts = []
                preprocessor = Preprocessor()
                analyzer = Analyzer()
                data = DataManager(config, cameras)
                stat = StatManager(config, cameras)
            end
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.DataManager = data;
            obj.StatManager = stat;
        end

        function init(obj)
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Sequence initialized.")
        end
        
        function run(obj, options)
            arguments
                obj
                options.verbose = obj.Run_Verbose
                options.verbose_layout = obj.Run_VerboseLayout
                options.verbose_data = obj.Run_VerboseData
                options.verbose_stat = obj.Run_VerboseStat
            end
            timer = tic;
            obj.RunNumber = obj.RunNumber + 1;
            obj.Live = struct('Info', struct('RunNumber', obj.RunNumber, ...
                                             'LatCalib', obj.Analyzer.LatCalib), ...
                              'Raw', [], 'Signal', [], 'Background', [], 'Analysis', []);
            sequence = obj.AcquisitionConfig.ActiveSequence;
            good = true;
            for i = 1: height(sequence)
                type = string(sequence.Type(i));
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                note = sequence.Note(i);
                config = obj.CameraManager.(camera).Config;
                % Run one step
                is_good = obj.runStep(type, camera, label, note, config);
                good = is_good && good;
            end
            if ~isempty(obj.LayoutManager)
                obj.renderLayout(options.verbose_layout)
            end
            if good || ~obj.AcquisitionConfig.DropBadFrames
                obj.addData(options.verbose_data)
                obj.addStat(options.verbose_stat)
            else
                obj.warn("Bad acquisition detected, data dropped.")
            end
            if obj.AcquisitionConfig.AbortAtEnd
                obj.abortAtEnd()
            end
            if options.verbose
                obj.info2("Sequence completed in %.3f s.", toc(timer))
            end
        end
    end
    
    methods (Access = protected, Abstract)
        is_good = runStep(obj, type, camera, label, note, config)
    end

    methods (Access = protected)
        function renderLayout(obj, verbose)
            obj.LayoutManager.update(obj.Live, 'verbose', verbose)
        end

        function addData(obj, verbose)
            obj.DataManager.add(obj.Live.Raw, "verbose", verbose);
        end

        function addStat(obj, verbose)
            obj.StatManager.add(obj.Live.Analysis, "verbose", verbose);
        end

        function abortAtEnd(~)
        end
    end
    
    methods (Access = protected, Hidden)
        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(RunNum: %d, Index: %d)", class(obj), obj.RunNumber, obj.DataManager.CurrentIndex);
        end
    end

    methods (Static)
        function [sequencer, acq_config, cameras] = struct2obj(class_name, data_struct, layout, preprocessor, analyzer, options)
            arguments
                class_name
                data_struct
                layout = []
                preprocessor = Preprocessor()
                analyzer = Analyzer()
                options.test_mode = false
            end
            [data, acq_config, cameras] = DataManager.struct2obj(data_struct, "test_mode", options.test_mode);
            sequencer = feval(class_name, acq_config, cameras, layout, preprocessor, analyzer, data);
            sequencer.info("Object created from structure.")
        end
    end
end
