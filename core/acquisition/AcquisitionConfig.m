classdef AcquisitionConfig < BaseProcessor
    
    properties (SetAccess = {?BaseObject})
        SequenceTable = SequenceRegistry.Full4Basic
        NumAcquisitions = 20
        NumStatistics = 1000
        Refresh = 0.01
        Timeout = Inf
        SampleInterval = 1
        DropBadFrames = true
        AbortAtEnd = true
    end
    
    % Properties that updates with SequenceTable
    properties (SetAccess = protected)
        ActiveDevices
        ActiveCameras
        ActiveProjectors
        ActiveSequence
        ActiveAcquisition
        ActiveAnalysis
        ActiveProjection
        ActiveMotion
        ImageList
        AcquisitionNote
        AnalysisNote
        AnalysisOutVars
        AnalysisOutData
        ProjectionNote
        MotionNote
    end

    methods
        function set.SequenceTable(obj, sequence)
            mustBeValidSequence(obj, sequence)
            obj.SequenceTable = sequence;
            obj.updateProp()
        end

        function contents = parseAnalysis2Content(obj, index_str)
            res = split(index_str, ": ");
            [camera, label] = res{:};
            if isfield(obj.AnalysisOutVars, camera) && isfield(obj.AnalysisOutVars.(camera), label)
                out_vars = obj.AnalysisOutVars.(camera).(label);
                contents = ("Analysis: " + out_vars')';
            else
                contents = string.empty;
            end
        end

        function disp(obj)
            disp@BaseObject(obj)
            disp(obj.SequenceTable)
        end
    end

    methods (Access = protected, Hidden)
        function updateProp(obj)
            [params, obj.AnalysisOutVars, obj.AnalysisOutData] = parseParams(obj, obj.SequenceTable);
            sequence = [obj.SequenceTable, params];
            obj.ActiveDevices = SequenceRegistry.getActiveDevices(sequence);
            obj.ActiveCameras = SequenceRegistry.getActiveCameras(sequence);
            obj.ActiveProjectors = SequenceRegistry.getActiveProjectors(sequence);
            obj.ActiveSequence = SequenceRegistry.getActiveSequence(sequence);
            obj.ActiveAcquisition = SequenceRegistry.getActiveAcquisition(sequence);
            obj.ActiveAnalysis = SequenceRegistry.getActiveAnalysis(sequence);
            obj.ActiveProjection = SequenceRegistry.getActiveProjection(sequence);
            obj.ActiveMotion = SequenceRegistry.getActiveMotion(sequence);
            obj.ImageList = getImageList(obj.ActiveAcquisition);
            obj.AcquisitionNote = getAcquisitionNote(obj.ActiveAcquisition);
            obj.AnalysisNote = getAnalysisNote(obj.ActiveAnalysis);
            obj.ProjectionNote = getProjectionNote(obj.ActiveProjection);
            obj.MotionNote = getMotionNote(obj.ActiveMotion);
        end
    end
    
    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseObject.struct2obj(s, AcquisitionConfig(), varargin{:});
        end
    end

end

% Get a cell array of strings with format "<camera>: <label>"
function image_list = getImageList(active_acquisition)
    num_images = height(active_acquisition);
    image_list = cell(num_images, 1);
    for i = 1:num_images
        camera = string(active_acquisition.Camera(i));
        label = active_acquisition.Label(i);
        image_list{i} = sprintf('%s: %s', camera, label);
    end
end

function res = getAcquisitionNote(active_acquisition)
    res = struct();
    for i = 1: height(active_acquisition)
        camera = string(active_acquisition.Camera(i));
        label = active_acquisition.Label(i);
        note = active_acquisition.Note(i);
        res.(camera).(label) = note;
    end
end

function res = getAnalysisNote(active_analysis)
    res = struct();
    for i = 1: height(active_analysis)
        camera = string(active_analysis.Camera(i));
        label = active_analysis.Label(i);
        note = active_analysis.Note(i);
        % Analysis may appear multiple times for the same device and label
        if isfield(res, camera) && isfield(res.(camera), label)
            res.(camera).(label) = res.(camera).(label) + ", " +  note;
        else
            res.(camera).(label) = note;
        end
    end
end

function res = getProjectionNote(active_projection)
    res = struct();
    for i = 1: height(active_projection)
        projector = string(active_projection.Camera(i));
        label = active_projection.Label(i);
        note = active_projection.Note(i);
        res.(projector).(label) = note;
    end
end

function res = getMotionNote(active_motion)
    res = struct();
    for i = 1: height(active_motion)
        driver = string(active_motion.Camera(i));
        label = active_motion.Label(i);
        note = active_motion.Note(i);
        res.(driver).(label) = note;
    end
end

function [params, analysis_outvars, analysis_outdata] = parseParams(obj, sequence)
    Params = cell(height(sequence), 1);
    analysis_outvars = struct();
    analysis_outdata = struct();
    for i = 1: height(sequence)
        operation = string(sequence.Type(i));
        camera = string(sequence.Camera(i));
        label = sequence.Label(i);
        note = sequence.Note(i);
        if camera == "--inactive--"
            continue
        end
        switch operation
            case "Start"
                Params{i} = parseString2Args(obj, note);
            case "Acquire"
                Params{i} = parseString2Processes(obj, note, ["Acquire", "Preprocess"], "full_struct", true);
            case "Start+Acquire"
                Params{i} = parseString2Processes(obj, note, ["Start", "Acquire", "Preprocess"], "full_struct", true);
            case "Analysis"
                [Params{i}, new_vars, new_data] = parseString2AnalysisProcesses(obj, note);
                if isfield(analysis_outvars, camera) && isfield(analysis_outvars.(camera), label)
                    analysis_outvars.(camera).(label) = [analysis_outvars.(camera).(label), new_vars];
                    analysis_outdata.(camera).(label) = [analysis_outdata.(camera).(label), new_data];
                else
                    analysis_outvars.(camera).(label) = new_vars;
                    analysis_outdata.(camera).(label) = new_data;
                end
            case "Project"
                Params{i} = parseString2Args(obj, note);
            case "Move"
                Params{i} = parseString2Args(obj, note);
        end
    end
    params = table(Params);
end

function [args, out_vars, out_data] = parseString2AnalysisProcesses(obj, note)
    [~, analysis_list] = enumeration('AnalysisRegistry');
    [processes, overall] = parseString2Processes(obj, note, analysis_list, "include_overall", true);
    process_name = string(fields(processes))';
    num_process = length(process_name);
    res = cell(2, num_process);
    out_vars = string.empty;
    out_data = string.empty;
    for i = 1: num_process
        p = process_name(i);
        res{1, i} = AnalysisRegistry.(p).FuncHandle;
        res{2, i} = processes.(p);
        out_vars = [out_vars, AnalysisRegistry.(p).OutputVars]; %#ok<AGROW>
        out_data = [out_data, AnalysisRegistry.(p).OutputData]; %#ok<AGROW>
    end
    args = [{"processes", res}, overall];
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
    % Erase white-space and split the string by ";"
    pieces = split(erase(note, " "), ";")';
    pieces = pieces(pieces ~= "");
    % For each string piece, try to parse as name=value
    args = cell(1, 2 * length(pieces));
    for i = 1: length(pieces)
        p = pieces(i);
        if contains(p, "=")
            vals = split(p, "=");
            if length(vals) == 2
                args{2*i-1} = vals(1);
                % Try parsing string as a valid MATLAB expression
                try
                    arg_val = eval(vals(2));
                catch me
                    % If failed, use pure string value
                    if (strcmp(me.identifier, 'MATLAB:UndefinedFunction'))
                        arg_val = vals(2);
                    else
                        rethrow(me)
                    end
                end
                args{2*i} = arg_val;
            else
                obj.error("Multiple '=' appears in the partitioned string '%s'.", p)
            end
        elseif p ~= ""
            args{2*i-1} = p;
            args{2*i} = true;
        end
    end
end

% Argument validation function to check if sequence table is valid
function mustBeValidSequence(obj, sequence)
    arguments
        obj
        sequence (:, 5) table
    end
    active_devices = SequenceRegistry.getActiveDevices(sequence);
    if isempty(active_devices)
        obj.error("Invalid sequence, no active device.")
    end
    for device = active_devices
        device_seq = sequence(sequence.Camera == device, :);
        started = string.empty();
        acquired = string.empty();
        moved = string.empty();
        projected = string.empty();
        for i = 1:height(device_seq)
            index = device_seq.Order(i);
            label = string(device_seq.Label(i));
            newerror = @(info) obj.error("[%d %s %s] Invalid sequence, %s.", index, device, label, info);
            operation = string(device_seq.Type(i));
            if label == ""
                newerror("empty label")
            end
            if label == "Config"
                newerror("'Config' is reserved and can not be used as label")
            end
            switch operation
                case {"Start", "Start+Acquire", "Acquire"}
                    if device.startsWith("DMD") || device.startsWith("Picomotor")
                        newerror("operation is only available for cameras")
                    end
                    if operation == "Start" || operation == "Start+Acquire"
                        if ismember(label, started)
                            newerror("label is started more than once, please use unique label")
                        end
                        started(end + 1) = label; %#ok<AGROW>
                    end
                    if operation == "Acquire" || operation == "Start+Acquire"
                        if isempty(started) || started(end) ~= label
                            newerror("missing 'Start' command before 'Acquire' command")
                        end
                        if ismember(label, acquired)
                            newerror("label is used more than once for 'Acquire', please use unique label")
                        end
                        acquired(end + 1) = label; %#ok<AGROW>
                        started(end) = [];
                    end
                case {"Analysis"}
                    if device.startsWith("DMD")
                    elseif device.startsWith("Picomotor")
                    elseif isempty(acquired) || ~ismember(label, acquired)
                        newerror("missing 'Acquire' command before 'Analysis' command")
                    end
                case {"Project"}
                    if ~device.startsWith("DMD")
                        newerror("operation 'Project' is only available for device name starting with 'DMD'")
                    end
                    if ismember(label, projected)
                        newerror("label is projected more than once, please use unique label")
                    end
                    projected(end + 1) = label; %#ok<AGROW>
                case {"Move"}
                    if ~device.startsWith("Picomotor")
                        newerror("operation 'Move' is only available for device name starting with 'Picomotor'")
                    end
                    if ismember(label, moved)
                        newerror("label is moved more than once, please use unique label")
                    end
                    moved(end + 1) = label; %#ok<AGROW>
                otherwise
                    newerror("operation not supported")
            end
        end
        if ~isempty(started)
            obj.error("Invalid sequence, missing acquire command for camera %s, labels %s.", ...
                device, strjoin(started, ","))
        end
    end
end
