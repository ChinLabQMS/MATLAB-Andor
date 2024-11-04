classdef AcquisitionConfig < BaseProcessor
    
    properties (SetAccess = {?BaseObject})
        SequenceTable = SequenceRegistry.Full4Analysis
        NumAcquisitions = 20
        NumStatistics = 2000
        Refresh = 0.01
        Timeout = Inf
        DropBadFrames = true
        AbortAtEnd = true
    end
    
    % Properties that updates with SequenceTable
    properties (SetAccess = protected)
        ActiveCameras
        ActiveSequence
        ActiveAcquisition
        ActiveAnalysis
        ActiveProjection
        AcquisitionNote
        AnalysisNote
        ProjectionNote
        StartParams
        AcquireParams
        PreprocessParams
        ProjectionParams
        AnalysisParams
        AnalysisOutVars
        AnalysisOutData
        ImageList
    end

    methods
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

        function set.SequenceTable(obj, sequence_table)
            arguments
                obj
                sequence_table {SequenceRegistry.mustBeValidSequence}
            end
            obj.SequenceTable = sequence_table;
            obj.updateProp()
        end

        function disp(obj)
            disp@BaseObject(obj)
            disp(obj.SequenceTable)
        end
    end

    methods (Access = protected, Hidden)
        function updateProp(obj)
            obj.ActiveCameras = SequenceRegistry.getActiveCameras(obj.SequenceTable);
            obj.ActiveSequence = SequenceRegistry.getActiveSequence(obj.SequenceTable);
            obj.ActiveAcquisition = SequenceRegistry.getActiveAcquisition(obj.SequenceTable);
            obj.ActiveAnalysis = SequenceRegistry.getActiveAnalysis(obj.SequenceTable);
            obj.ActiveProjection = SequenceRegistry.getActiveProjection(obj.SequenceTable);
            [obj.AcquisitionNote, obj.AnalysisNote, obj.ProjectionNote] = parseSequenceNote(obj.ActiveSequence);
            [obj.StartParams, obj.AcquireParams, obj.PreprocessParams] = parseAcquisitionNoteFull(obj, obj.AcquisitionNote);
            [obj.AnalysisParams, obj.AnalysisOutVars, obj.AnalysisOutData] = parseAnalysisNoteFull(obj, obj.AnalysisNote);
            obj.ProjectionParams = parseProjectionNoteFull(obj, obj.ProjectionNote);
            obj.ImageList = getImageList(obj.ActiveAcquisition);
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

% Parse the notes in active sequence to different structures
function [acquisition_note, analysis_note, projection_note] = parseSequenceNote(sequence)
    acquisition_note = struct();
    analysis_note = struct();
    projection_note = struct();
    for i = 1: height(sequence)
        type = string(sequence.Type(i));
        camera = string(sequence.Camera(i));
        label = sequence.Label(i);
        note = sequence.Note(i);
        switch type
            case {"Start", "Acquire", "Start+Acquire"}
                if isfield(acquisition_note, camera) && isfield(acquisition_note.(camera), label) && note ~= ""
                    acquisition_note.(camera).(label) = acquisition_note.(camera).(label) + "," + note;
                else
                    acquisition_note.(camera).(label) = note;
                end
            case "Analysis"
                if isfield(analysis_note, camera) && isfield(analysis_note.(camera), label) && note ~= ""
                    analysis_note.(camera).(label) = analysis_note.(camera).(label) + "," + note;
                else
                    analysis_note.(camera).(label) = note;
                end
            case "Projection"
                if isfield(projection_note, camera) && isfield(projection_note.(camera), label) && note ~= ""
                    projection_note.(camera).(label) = projection_note.(camera).(label) + "," + note;
                else
                    projection_note.(camera).(label) = note;
                end
        end
    end
end

% Parse a structure of notes into structure of cell array of parameters
function [start, acquire, preprocess] = parseAcquisitionNoteFull(obj, note_full)
    start = struct();
    acquire = struct();
    preprocess = struct();
    for camera = string(fields(note_full))'
        for label = string(fields(note_full.(camera)))'
            [start.(camera).(label), acquire.(camera).(label), preprocess.(camera).(label)] = ...
                parseAcquisitionNote(obj, note_full.(camera).(label));
        end
    end
end

% Parse the acquisition note into three cell array of parameters
function [start, acquire, preprocess] = parseAcquisitionNote(obj, note)
    start = {};
    acquire = {'refresh', obj.Refresh, 'timeout', obj.Timeout};
    preprocess = {};
    params = parseString2Processes(obj, note, ["Start", "Acquire", "Preprocess"]);
    if isfield(params, "Start")
        start = [start, params.Start];
    end
    if isfield(params, "Acquire")
        acquire = [acquire, params.Acquire];
    end
    if isfield(params, "Preprocess")
        preprocess = [preprocess, params.Preprocess];
    end
end

% Parse a structure of notes into structure of cell array of parameters
function [processes, out_vars, out_data] = parseAnalysisNoteFull(obj, note_full)
    processes = struct();
    out_vars = struct();
    out_data = struct();
    for camera = string(fields(note_full))'
        for label = string(fields(note_full.(camera)))'
            [processes.(camera).(label), out_vars.(camera).(label), out_data.(camera).(label)] = ...
                parseAnalysisNote(obj, note_full.(camera).(label));
        end
    end
end

% Parse the analysis note into cell arrays of analysis processes
function [processes, out_vars, out_data] = parseAnalysisNote(obj, note)
    [~, analysis_list] = enumeration('AnalysisRegistry');
    args = parseString2Processes(obj, note, analysis_list);
    process_names = string(fields(args))';
    processes = cell(1, length(process_names));
    out_vars = string.empty;
    out_data = string.empty;
    for i = 1:length(process_names)
        p = process_names(i);
        processes{i} = [{AnalysisRegistry.(p).FuncHandle}, args.(p)];
        out_vars = [out_vars, AnalysisRegistry.(p).OutputVars]; %#ok<AGROW>
        out_data = [out_data, AnalysisRegistry.(p).OutputData]; %#ok<AGROW>
    end
end

% Parse a structure of notes into structure of cell array of parameters
function params = parseProjectionNoteFull(obj, note_full)
    params = struct();
    for camera = string(fields(note_full))'
        for label = string(field(note_full.(camera)))'
            [params.(camera).(label)] = ...
                parseProjectionNote(obj, note_full.(camera).(label));
        end
    end
end

% Parse the projection note into cell array of projection parameters
function params = parseProjectionNote(obj, note)
    params = {};
    obj.warn2("Not implemented, unable to parse '%s'.", note)
end

% Split structure of arguments by processes names, return a structure
function processes = parseString2Processes(obj, note, process_list)
    args = parseString2Args(obj, note);
    curr = [];
    processes = struct();
    for name = string(fields(args))'
        if ismember(name, process_list) && args.(name)
            % Start a new process
            curr = name;
            processes.(curr) = {};
        elseif ~isempty(curr)
            % Parse the arguments as parameter of current process
            processes.(curr) = [processes.(curr), {name, args.(name)}];
        else
            obj.error("Unable to parse argument name '%s', no identifier before parameters.", name)
        end
    end
end

% Parse the note to a structure
function args = parseString2Args(obj, note)
    % Erase white-space and split the string by ","
    pieces = split(erase(note, " "), ",")';
    % For each string piece, try to parse as name=value
    args = struct();
    for p = pieces
        if contains(p, "=")
            vals = split(p, "=");
            if length(vals) == 2
                arg_val = double(string(vals(2)));
                if isnan(arg_val) && ~ismember(vals(2), ["Nan", "NaN", "nan"])
                    args.(vals(1)) = vals(2);
                else
                    args.(vals(1)) = arg_val;
                end
            else
                obj.error("Multiple '=' appears in the partitioned string '%s'.", p)
            end
        elseif p ~= ""
            args.(p) = true;
        end
    end
end
