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
    end
    
    % Live data
    properties (SetAccess = protected)
        Timer
        Live
        SequenceStep
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
        function run(obj, options)
            arguments
                obj
                options.verbose = obj.Run_Verbose
            end
            timer = tic;
            if obj.AcquisitionConfig.AbortAtEnd
                c_obj = onCleanup(@() obj.CameraManager.abortAcquisition(obj.AcquisitionConfig.ActiveCameras));
            end
            obj.Live.init()
            for step = obj.SequenceStep
                [func, args] = step{:};
                func(args{:})
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj)
            end
            if (~obj.Live.BadFrameDetected || ~obj.AcquisitionConfig.DropBadFrames)
                if (rem(obj.Live.RunNumber, obj.AcquisitionConfig.SampleInterval) == 0)
                    obj.addData()
                end
                obj.addStat()
            else
                obj.warn2("Bad acquisition detected, data dropped.")
            end
            if options.verbose
                obj.info2("Sequence completed in %.3f s.", toc(timer))
            end
        end

        function initSequence(obj)
            active_sequence = obj.AcquisitionConfig.ActiveSequence;
            steps = {};
            for i = 1: height(active_sequence)
                operation = string(active_sequence.Type(i));
                camera = string(active_sequence.Camera(i));
                label = active_sequence.Label(i);
                params = active_sequence.Params{i};
                switch operation
                    case "Start"
                        func = @(varargin) obj.start(camera, label, varargin{:});
                        args = [{"label", label}, params];
                        new_steps = [{func}; {args}];
                    case "Acquire"
                        func1 = @(varargin) obj.acquire(camera, label, varargin{:});
                        func2 = @(varargin) obj.preprocess(camera, label, varargin{:});
                        args1 = [{"label", label}, params.Acquire];
                        args2 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}; {args1}, {args2}];
                    case "Start+Acquire"
                        func1 = @(varargin) obj.start(camera, label, varargin{:});
                        func2 = @(varargin) obj.acquire(camera, label, varargin{:});
                        func3 = @(varargin) obj.preprocess(camera, label, varargin{:});
                        args1 = [{"label", label}, params.Start];
                        args2 = [{"label", label}, params.Acquire];
                        args3 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}, {func3}; {args1}, {args2}, {args3}];
                    case "Analysis"
                        func = @(varargin) obj.analyze(camera, label, varargin{:});
                        args = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params];
                        new_steps = [{func}; {args}];
                    case "Projection"
                        func = @(varargin) obj.project(camera, label, varargin{:});
                        args = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params];
                        new_steps = [{func}; {args}];
                end
                steps = [steps, new_steps]; %#ok<AGROW>
            end
            obj.SequenceStep = steps;
        end
    end

    methods (Access = protected, Hidden)
        function start(obj, camera, ~, varargin)
            obj.CameraManager.(camera).startAcquisition(varargin{:});
        end

        function acquire(obj, camera, label, varargin)
            obj.Live.Raw.(camera).(label) = obj.CameraManager.(camera).acquire(varargin{:});
        end

        function preprocess(obj, camera, label, varargin)
            [signal, background] = obj.Preprocessor.process(obj.Live.Raw.(camera).(label), varargin{:});
            obj.Live.Signal.(camera).(label) = signal;
            obj.Live.Background.(camera).(label) = background;
        end
        
        function analyze(obj, camera, label, varargin)
            obj.Analyzer.analyze(obj.Live, varargin{:});
        end
        
        function project(obj, camera, label, varargin)
            obj.warn2("[%s %s] Projection method is not implemented.", camera, label)
        end

        function addData(obj)
            obj.DataStorage.add(obj.Live.Raw);
        end

        function addStat(obj)
            obj.StatStorage.add(obj.Live.Analysis);
        end
    end

    methods (Access = protected, Hidden, Sealed)
        % Override the default getStatusLabel method from BaseObject
        function label = getStatusLabel(obj)
            label = sprintf("%s(RunNum:%d, DataIdx:%d, StatIdx:%d)", ...
                class(obj), obj.Live.RunNumber, obj.DataStorage.CurrentIndex, obj.StatStorage.CurrentIndex);
        end
    end
end
