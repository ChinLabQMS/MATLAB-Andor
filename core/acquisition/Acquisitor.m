classdef Acquisitor < BaseSequencer

    % Class properties that control the live acquisition behaviors
    properties (Constant)
        Run_VerboseStart = false
        Run_VerboseAcquire = true
        Run_VerbosePreprocess = false
        Run_VerboseAnalysis = false
    end

    methods
        function obj = Acquisitor(varargin)
            obj@BaseSequencer(varargin{:})
        end

        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.AcquisitionConfig.ActiveCameras)
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.DataManager.init()
            obj.StatManager.init()
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Acquisition initialized.")
        end
    end

    methods (Access = protected)
        function is_good = runStep(obj, type, camera, label, note, config, options)
            arguments
                obj
                type
                camera
                label
                note
                config
                options.verbose_start = obj.Run_VerboseStart
                options.verbose_acquire = obj.Run_VerboseAcquire
                options.verbose_preprocess = obj.Run_VerbosePreprocess
                options.verbose_analysis = obj.Run_VerboseAnalysis
            end
            is_good = true;
            info = builtin('struct', 'camera', camera, 'label', label, 'note', note, ...
                          'config', config);
            if type == "Start" || type == "Start+Acquire"
                obj.CameraManager.(camera).startAcquisition("verbose", options.verbose_start)
            end
            if type == "Acquire" || type == "Start+Acquire"
                args = obj.AcquisitionConfig.AcquisitionParams.(camera).(label);
                % Acquire raw images
                [obj.Live.Raw.(camera).(label), status] = obj.CameraManager.(camera).acquire(info, ...
                    'refresh', obj.AcquisitionConfig.Refresh, 'timeout', obj.AcquisitionConfig.Timeout, ...
                    'verbose', options.verbose_acquire, args{:});
                is_good = is_good && (status == "good");
                % Preprocess raw images
                [obj.Live.Signal.(camera).(label), obj.Live.Background.(camera).(label)] = obj.Preprocessor.process( ...
                    obj.Live.Raw.(camera).(label), info, ...
                    "verbose", options.verbose_preprocess);
            end
            if type == "Analysis"
                % Generate analysis statistics
                info.processes = obj.AcquisitionConfig.AnalysisProcesses.(camera).(label);
                obj.Live.Analysis.(camera).(label) = obj.Analyzer.analyze( ...
                    obj.Live.Signal.(camera).(label), info, ...
                    "verbose", options.verbose_analysis);
            end
        end
    end

end
