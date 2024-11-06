classdef BaseSequencer < BaseObject
    %BASESEQUENCER Base class for all sequence runner.
    
    % Handle to other objects
    properties (SetAccess = immutable)
        AcquisitionConfig
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
        DataStorage
        StatStorage
    end
    
    % Run verbose parameters
    properties (Constant)
        Run_Verbose = true
        Run_VerboseStart = false
        Run_VerboseAcquire = true
        Run_VerbosePreprocess = false
        Run_VerboseAnalysis = false
        Run_VerboseLayout = true
        Run_VerboseData = true
        Run_VerboseStat = false
    end
    
    % Live data
    properties (SetAccess = protected)
        Timer
        RunNumber
        Raw
        Signal
        Background
        Analysis
        BadFrameDetected
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
                data = DataStorage(config, cameras)
                stat = StatStorage(config, cameras)
            end
            % Make sure handles are referenced correctly
            obj.assert((data.AcquisitionConfig == config) && (data.CameraManager == cameras) ...
                 && (stat.AcquisitionConfig == config) && (stat.CameraManager == cameras), ...
                 'Handles are not referenced correctly.')
            % Initialize immutable handles
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.DataStorage = data;
            obj.StatStorage = stat;
        end
    end

    methods (Sealed)
        % Run the sequence once
        function run(obj, opt1, opt2)
            arguments
                obj
                opt1.verbose = obj.Run_Verbose
                opt2.verbose_start = obj.Run_VerboseStart
                opt2.verbose_acquire = obj.Run_VerboseAcquire
                opt2.verbose_preprocess = obj.Run_VerbosePreprocess
                opt2.verbose_analysis = obj.Run_VerboseAnalysis
                opt2.verbose_layout = obj.Run_VerboseLayout
                opt2.verbose_data = obj.Run_VerboseData
                opt2.verbose_stat = obj.Run_VerboseStat
            end
            timer = tic;
            if obj.AcquisitionConfig.AbortAtEnd
                c_obj = onCleanup(@()obj.abortAtEnd);
            end
            obj.RunNumber = obj.RunNumber + 1;
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Analysis = [];
            obj.BadFrameDetected = false;
            sequence = obj.AcquisitionConfig.ActiveSequence;
            for i = 1: height(sequence)
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                config = obj.CameraManager.(camera).Config;
                operation = string(sequence.Type(i));
                if operation == "Start" || operation == "Start+Acquire"
                    obj.runStart(camera, label, config, opt2.verbose_start)
                end
                if operation == "Acquire" || operation == "Start+Acquire"
                    obj.runAcquire(camera, label, config, opt2.verbose_acquire);
                    obj.runPreprocess(camera, label, config, opt2.verbose_preprocess)                
                end
                if operation == "Analysis"
                    obj.runAnalysis(camera, label, config, opt2.verbose_analysis)
                end
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj, 'verbose', opt2.verbose_layout)
            end
            if (~obj.BadFrameDetected || ~obj.AcquisitionConfig.DropBadFrames)
                if (rem(obj.RunNumber, obj.AcquisitionConfig.SampleInterval) == 0)
                    obj.addData(opt2.verbose_data)
                end
                obj.addStat(opt2.verbose_stat)
            else
                obj.warn2("Bad acquisition detected, data dropped.")
            end
            if opt1.verbose
                obj.info2("Sequence completed in %.3f s.", toc(timer))
            end
        end
    end

    methods (Access = protected, Hidden)
        function runStart(obj, camera, label, ~, verbose)
            args = [{"label", label, "verbose", verbose}, obj.AcquisitionConfig.StartParams.(camera).(label)];
            obj.CameraManager.(camera).startAcquisition(args{:})
        end

        function runAcquire(obj, camera, label, ~, verbose)
            args = [{"label", label, "verbose", verbose}, obj.AcquisitionConfig.AcquireParams.(camera).(label)];
            [obj.Raw.(camera).(label), is_good] = obj.CameraManager.(camera).acquire(args{:});
            if ~is_good
                obj.BadFrameDetected = true;
            end
        end

        function runPreprocess(obj, camera, label, config, verbose)
            args = [{"camera", camera, "label", label, "config", config, "verbose", verbose}, ...
                obj.AcquisitionConfig.PreprocessParams.(camera).(label)];
            [obj.Signal.(camera).(label), obj.Background.(camera).(label)] = obj.Preprocessor.process( ...
                obj.Raw.(camera).(label), args{:});
        end

        function runAnalysis(obj, camera, label, config, verbose)
            args = {obj.AcquisitionConfig.AnalysisParams.(camera).(label), ...
                "camera", camera, "label", label, "config", config, "verbose", verbose};
            [obj.Analysis.(camera).(label)] = obj.Analyzer.analyze(obj.Signal, args{:});
        end

        function addData(obj, verbose)
            obj.DataStorage.add(obj.Raw, "verbose", verbose);
        end

        function addStat(obj, verbose)
            obj.StatStorage.add(obj.Analysis, "verbose", verbose);
        end

        function abortAtEnd(obj)
            obj.CameraManager.abortAcquisition(obj.AcquisitionConfig.ActiveCameras)
        end
    end

    methods (Access = protected, Hidden, Sealed)
        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(RunNum:%d, DataIdx:%d, StatIdx:%d)", ...
                class(obj), obj.RunNumber, obj.DataStorage.CurrentIndex, obj.StatStorage.CurrentIndex);
        end
    end
end
