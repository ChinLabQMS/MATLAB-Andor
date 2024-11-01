classdef BaseSequencer < BaseObject
    %BASESEQUENCER Base class for all sequence runner.

    properties (SetAccess = immutable)
        AcquisitionConfig
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
        DataStorage
        StatStorage
    end

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
                data = DataStorage(config, cameras)
                stat = StatStorage(config, cameras)
            end
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.DataStorage = data;
            obj.StatStorage = stat;
        end
        
        function run(obj, options)
            arguments
                obj
                options.verbose = obj.Run_Verbose
                options.verbose_start = obj.Run_VerboseStart
                options.verbose_acquire = obj.Run_VerboseAcquire
                options.verbose_preprocess = obj.Run_VerbosePreprocess
                options.verbose_analysis = obj.Run_VerboseAnalysis
                options.verbose_layout = obj.Run_VerboseLayout
                options.verbose_data = obj.Run_VerboseData
                options.verbose_stat = obj.Run_VerboseStat
            end
            timer = tic;
            obj.RunNumber = obj.RunNumber + 1;
            obj.Live = struct('Info', struct('RunNumber', obj.RunNumber, ...
                                             'LatCalib', obj.Analyzer.LatCalib, ...
                                             'BadFrameDetected', false), ...
                              'Raw', [], 'Signal', [], 'Background', [], 'Analysis', []);
            sequence = obj.AcquisitionConfig.ActiveSequence;
            for i = 1: height(sequence)
                type = string(sequence.Type(i));
                camera = string(sequence.Camera(i));
                label = sequence.Label(i);
                note = sequence.Note(i);
                config = obj.CameraManager.(camera).Config.struct();
                % Run one step
                info = struct('camera', camera, 'config', config, 'label', label, 'note', note);
                if type == "Start" || type == "Start+Acquire"
                    obj.startAcquisition(info, "verbose", options.verbose_start)
                end
                if type == "Acquire" || type == "Start+Acquire"
                    args = [obj.AcquisitionConfig.AcquisitionParams.(camera).(label), ...
                        {'verbose', options.verbose_acquire}];
                    % Acquire raw images
                    obj.acquireImage(info, args{:});
                    % Preprocess raw images
                    [obj.Live.Signal.(camera).(label), obj.Live.Background.(camera).(label)] = obj.Preprocessor.process( ...
                        obj.Live.Raw.(camera).(label), info, 'verbose', options.verbose_preprocess);
                end
                if type == "Analysis"
                    % Generate analysis statistics
                    if obj.AcquisitionConfig.DropBadFrames && obj.Live.Info.BadFrameDetected
                        continue
                    end
                    processes = obj.AcquisitionConfig.AnalysisProcess.(camera).(label);
                    obj.Live.Analysis.(camera).(label) = obj.Analyzer.analyze( ...
                        obj.Live.Signal.(camera).(label), info, processes, 'verbose', options.verbose_analysis);
                end
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj.Live, 'verbose', options.verbose_layout)
            end
            if ~obj.Live.Info.BadFrameDetected || ~obj.AcquisitionConfig.DropBadFrames
                obj.addData(options.verbose_data)
                obj.StatStorage.add(obj.Live.Analysis, "verbose", options.verbose_stat);
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

    methods (Access = protected, Hidden, Abstract)
        startAcquisition(obj, info, varargin)            
        acquireImage(obj, info, varargin)
        addData(obj, verbose)
        abortAtEnd(obj)
    end

    methods (Access = protected, Hidden)
        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(RunNum: %d, Index: %d)", class(obj), obj.RunNumber, obj.DataStorage.CurrentIndex);
        end
    end
end
