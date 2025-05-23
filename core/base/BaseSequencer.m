classdef (Abstract) BaseSequencer < BaseObject
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
        Live
    end
    
    % Live data
    properties (SetAccess = protected)
        Timer
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
            obj.Live = LiveData(obj.CameraManager, obj.Preprocessor, obj.Analyzer);
        end
    end

    methods (Sealed)
        % Run the sequence once
        function run(obj, options)
            arguments
                obj
                options.verbose = true
            end
            timer = tic;
            if obj.AcquisitionConfig.AbortAtEnd
                c_obj = onCleanup(@obj.abortAtEnd);
            end
            obj.Live.init()
            % Run the steps defined in SequenceTable with parsed parameters
            for step = obj.SequenceStep
                [func, args] = step{:};
                func(args{:})
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj.Live)
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
    end

    methods (Access = protected, Hidden)
        % Perform input arguments parsing at the beginning
        function initSequence(obj)
            obj.StatStorage.init()
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.Timer = tic;
            obj.Live.reset()
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
                        args1 = [{"label", label, "refresh", obj.AcquisitionConfig.Refresh, "timeout", obj.AcquisitionConfig.Timeout}, params.Acquire];
                        args2 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}; {args1}, {args2}];
                    case "Start+Acquire"
                        func1 = @(varargin) obj.start(camera, label, varargin{:});
                        func2 = @(varargin) obj.acquire(camera, label, varargin{:});
                        func3 = @(varargin) obj.preprocess(camera, label, varargin{:});
                        args1 = [{"label", label}, params.Start];
                        args2 = [{"label", label, "refresh", obj.AcquisitionConfig.Refresh, "timeout", obj.AcquisitionConfig.Timeout}, params.Acquire];
                        args3 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}, {func3}; {args1}, {args2}, {args3}];
                    case "Analysis"
                        func = @(varargin) obj.analyze(camera, label, varargin{:});
                        controller = obj.CameraManager.(camera);
                        if isa(controller, "Camera")
                            args = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params];
                        elseif isa(controller, "PicomotorDriver") || isa(controller, "Projector")
                            args = [{"camera", camera, "label", label, "config", []}, params];
                        else
                            obj.error("Unkown device type for initializing analysis step: %s.", class(controller))
                        end
                        new_steps = [{func}; {args}];
                    case "Project"
                        func = @(varargin) obj.project(camera, label, varargin{:});
                        new_steps = [{func}; {params}];
                    case "Move"
                        func = @(varargin) obj.move(camera, label, varargin{:});
                        new_steps = [{func}; {params}];
                    otherwise
                        obj.error('Unrecongnized operation: %s!', operation)
                end
                steps = [steps, new_steps]; %#ok<AGROW>
            end
            obj.SequenceStep = steps;
        end
        
        % Prepare camera to be ready for trigger
        function start(obj, camera, ~, varargin)
            obj.CameraManager.(camera).startAcquisition(varargin{:});
        end
        
        % Acquire images from cameras
        function acquire(obj, camera, label, varargin)
            [obj.Live.Raw.(camera).(label), is_good] = obj.CameraManager.(camera).acquire(varargin{:});
            if ~is_good
                obj.Live.BadFrameDetected = true;
            end
        end
        
        % Preprocess the image to remove background
        function preprocess(obj, camera, label, varargin)
            [signal, background, noise] = obj.Preprocessor.process(obj.Live.Raw.(camera).(label), varargin{:});
            obj.Live.Signal.(camera).(label) = signal;
            obj.Live.Background.(camera).(label) = background;
            obj.Live.Noise.(camera).(label) = noise;
        end
        
        % Analyze the images if there is no bad shot
        function analyze(obj, ~, ~, varargin)
            if (~obj.Live.BadFrameDetected || ~obj.AcquisitionConfig.DropBadFrames)
                obj.Analyzer.analyze(obj.Live, varargin{:});
            end
        end
        
        % Project patterns
        function project(obj, projector, ~, varargin)
            obj.CameraManager.(projector).project(obj.Live, varargin{:})
        end

        % Move picomotor piezo actuators
        function move(obj, driver, ~, varargin)
            obj.CameraManager.(driver).move(varargin{:})
        end
        
        % Add raw data to storage
        function addData(obj)
            obj.DataStorage.add(obj.Live.Raw);
        end
        
        % Add live analysis to storage
        function addStat(obj)
            obj.StatStorage.add(obj.Live.Analysis);
        end
        
        function abortAtEnd(obj)
            obj.CameraManager.abortAcquisition(obj.AcquisitionConfig.ActiveCameras);
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
