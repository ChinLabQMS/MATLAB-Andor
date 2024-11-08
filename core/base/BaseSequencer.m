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
                c_obj = onCleanup(@()obj.abortAtEnd);
            end
            obj.Live.init()
            % Run the sequence
            for step = obj.SequenceStep
                step{1}(step{2}{:})
            end
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.update(obj)
            end
            if (~obj.Live.BadFrameDetected || ~obj.AcquisitionConfig.DropBadFrames)
                if (rem(obj.RunNumber, obj.AcquisitionConfig.SampleInterval) == 0)
                    obj.addData(opt2.verbose_data)
                end
                obj.addStat(opt2.verbose_stat)
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
                note = active_sequence.Note(i);
                switch operation
                    case "Start"
                        func = @(varargin) obj.start(camera, label, varargin{:});
                        args = [{"label", label}, parseString2Args(obj, note)];
                        new_steps = [{func}; {args}];
                    case "Acquire"
                        params = parseString2Processes(obj, note, ["Acquire", "Preprocess"], "full_struct", true);
                        func1 = @(varargin) obj.acquire(camera, label, varargin{:});
                        func2 = @(varargin) obj.preprocess(camera, label, varargin{:});
                        args1 = [{"label", label}, params.Acquire];
                        args2 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}; {args1}, {args2}];
                    case "Start+Acquire"
                        params = parseString2Processes(obj, note, ["Start", "Acquire", "Preprocess"], "full_struct", true);
                        func1 = @(varargin) obj.start(camera, label, varargin{:});
                        func2 = @(varargin) obj.acquire(camera, label, varargin{:});
                        func3 = @(varargin) obj.preprocess(camera, label, varargin{:});
                        args1 = [{"label", label}, params.Start];
                        args2 = [{"label", label}, params.Acquire];
                        args3 = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, params.Preprocess];
                        new_steps = [{func1}, {func2}, {func3}; {args1}, {args2}, {args3}];
                    case "Analysis"
                        func = @(varargin) obj.analyze(camera, label, varargin{:});
                        args = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, parseString2AnalyzeProcesses(obj, note)];
                        new_steps = [{func}; {args}];
                    case "Projection"
                        func = @(varargin) obj.project(camera, label, varargin{:});
                        args = [{"camera", camera, "label", label, "config", obj.CameraManager.(camera).Config}, parseString2Args(obj, note)];
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
            analysis = obj.Analyzer.analyze(obj.Live, varargin{:});
            if isfield(obj.Live.Analysis, camera) && isfield(obj.Live.Analysis.(camera), label)
                for field = string(fields(obj.Live.Analysis.(camera).(label)))'
                    obj.Live.Analysis.(camera).(label).(field) = analysis.(field);
                end
            else
                obj.Live.Analysis.(camera).(label) = analysis;
            end
        end
        
        function project(obj, camera, label, varargin)
            obj.warn2("[%s %s] Projection method is not implemented.", camera, label)
        end

        function addData(obj, verbose)
            obj.DataStorage.add(obj.Live.Raw, "verbose", verbose);
        end

        function addStat(obj, verbose)
            obj.StatStorage.add(obj.Live.Analysis, "verbose", verbose);
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

function args = parseString2AnalyzeProcesses(obj, note)
    [~, analysis_list] = enumeration('AnalysisRegistry');
    [processes, overall] = parseString2Processes(obj, note, analysis_list, "include_overall", true);
    args = [{"processes", processes}, overall];
end

% Split structure of arguments by processes names, return a
% structure of cell array
function [processes, overall] = parseString2Processes(obj, note, process_list, options)
    arguments
        obj
        note
        process_list
        options.full_struct = false
        options.include_overall = false
    end
    args = parseString2Args(obj, note);
    curr = [];
    processes = struct();
    overall = {};
    for i = 1: 2: length(args)
        name = args{i};
        value = args{i + 1};
        if ismember(name, process_list) && value
            % Start a new process
            curr = name;
            processes.(curr) = {};
        elseif ~isempty(curr)
            % Parse the arguments as parameter of current process
            processes.(curr) = [processes.(curr), {name, value}];
        elseif options.include_overall
            % If there is no identifier, parse it as overall params
            overall = [overall, {name, value}]; %#ok<AGROW>
        else
            obj.error("Unable to parse argument name '%s', no identifier before parameters.", name)
        end
    end
    if options.full_struct
        for p = process_list
            if ~isfield(processes, p)
                processes.(p) = {};
            end
        end
    end
end

% Parse the note to a cell array of name-value pairs
function args = parseString2Args(obj, note)
    % Erase white-space and split the string by ","
    pieces = split(erase(note, " "), ",")';
    pieces = pieces(pieces ~= "");
    % For each string piece, try to parse as name=value
    args = cell(1, 2 * length(pieces));
    for i = 1: length(pieces)
        p = pieces(i);
        if contains(p, "=")
            vals = split(p, "=");
            if length(vals) == 2
                args{2*i-1} = vals(1);
                arg_val = double(string(vals(2)));
                if isnan(arg_val) && ~ismember(vals(2), ["Nan", "NaN", "nan"])
                    args{2*i} = vals(2);
                else
                    args{2*i} = arg_val;
                end
            else
                obj.error("Multiple '=' appears in the partitioned string '%s'.", p)
            end
        elseif p ~= ""
            args{2*i-1} = p;
            args{2*i} = true;
        end
    end
end
