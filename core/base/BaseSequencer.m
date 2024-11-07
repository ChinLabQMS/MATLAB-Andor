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
        Run_VerboseLayout = true
        Run_VerboseData = true
        Run_VerboseStat = false
    end
    
    % Live data
    properties (SetAccess = protected)
        Timer
        Live
        Steppers
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
                opt2.verbose_layout = obj.Run_VerboseLayout
                opt2.verbose_data = obj.Run_VerboseData
                opt2.verbose_stat = obj.Run_VerboseStat
            end
            timer = tic;
            if obj.AcquisitionConfig.AbortAtEnd
                c_obj = onCleanup(@()obj.abortAtEnd);
            end
            obj.Live.init()
            % Run the sequence
            for i = 1: length(obj.Steppers)
                obj.Steppers{i}.run()
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
        function initSteppers(obj)
            sequence = obj.AcquisitionConfig.ActiveSequence;
            obj.Steppers = {};
            for i = 1: height(sequence)
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                note = sequence.Note(i);
                operation = string(sequence.Type(i));
                switch operation
                    case "Start"
                        obj.Steppers = [obj.Steppers, {StartStepper(obj, camera, label, note)}];
                    case "Start+Acquire"
                        obj.Steppers = [obj.Steppers, ...
                            {StartStepper(obj, camera, label, note, ...
                            "full", false, "composite_name", "Start", ...
                            "process_list", ["Start", "Acquire", "Preprocess"]), ...
                            AcquireStepper(obj, camera, label, note, ...
                            "full", false, "composite_name", "Acquire", ...
                            "process_list", ["Start", "Acquire", "Preprocess"]), ...
                            PreprocessStepper(obj, camera, label, note, ...
                            "full", false, "composite_name", "Preprocess", ...
                            "process_list", ["Start", "Acquire", "Preprocess"])}
                            ];
                    case "Acquire"
                        obj.Steppers = [obj.Steppers, ...
                            {AcquireStepper(obj, camera, label, note, ...
                            "full", false, "composite_name", "Acquire", ...
                            "process_list", ["Acquire", "Preprocess"]), ...
                            PreprocessStepper(obj, camera, label, note, ...
                            "full", false, "composite_name", "Preprocess", ...
                            "process_list", ["Acquire", "Preprocess"])}
                            ];
                    case "Analysis"
                        obj.Steppers = [obj.Steppers, {AnalysisStepper(obj, camera, label, note)}];
                end
            end
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
