classdef SequenceRegistry < BaseObject %#ok<*AGROW>
    % SequenceRegistry: Registry of acquisition sequences.

    properties (Constant)
        Empty = makeSequence([], [], [], [], 10)
        Zelux2Basic = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux"], ...
            ["Lattice", "DMD", "Lattice", "DMD"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis"], ...
            ["", "", "", ""])
        Zelux2Basic2 = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Zelux", "Zelux"], ...
            ["Lattice", "DMD", "Lattice", "DMD", "Lattice", "DMD"], ...
            ["Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "", ""])
        AndorBasic = makeSequence( ...
            ["Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "", ""])
        Full4Basic = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Lattice", "DMD", "Lattice", "DMD", "Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis", "Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "", "", "", "", "FitCenter", "FitCenter"])
        Full4Analysis = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Lattice", "DMD", "Lattice", "DMD", "Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis", "Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "CalibLatR", "FitCenter", "", "", "", "", "FitCenter, CalibLatR", "FitCenter, CalibLatR"])
        Full4Analysis2 = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Zelux", "Zelux", "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Lattice", "DMD", "Lattice", "DMD", "Lattice", "DMD", "Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis", "Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "CalibLatR", "FitCenter", "", "", "", "", "FitCenter, CalibLatR", "FitCenter, CalibLatR"])
    end

    methods (Static)
        function active_cameras = getActiveCameras(sequence)
            active_cameras = unique(sequence.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"))';
        end

        function active_sequence = getActiveSequence(sequence)
            active_sequence = sequence(sequence.Camera ~= "--inactive--" & ...
                ~(sequence.Type == "Analysis" & sequence.Note == ""), :);
        end

        function active_acquisition = getActiveAcquisition(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_acquisition = active_sequence((active_sequence.Type == "Acquire") | ...
                (active_sequence.Type == "Start+Acquire"), :);
        end

        function active_analysis = getActiveAnalysis(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_analysis = active_sequence(active_sequence.Type == "Analysis" & ...
                active_sequence.Note ~= "", :);
        end

        function mustBeValidSequence(sequence)
            arguments
                sequence (:, 5) table
            end
            active_cameras = SequenceRegistry.getActiveCameras(sequence);
            if isempty(active_cameras)
                error("Invalid sequence, no active camera.")
            end
            for camera = active_cameras
                camera_seq = sequence(sequence.Camera == camera, :);
                started = string.empty;
                acquired = string.empty;
                analyzed = string.empty;
                for i = 1:height(camera_seq)
                    label = string(camera_seq.Label(i));
                    type = string(camera_seq.Type(i));
                    if label == ""
                        error("Invalid sequence, empty label.")
                    end
                    if label == "Config"
                        error("Invalid sequence, 'Config' is reserved for camera sequenceuration and can not be used as label.")
                    end
                    if type == "Start" || type == "Start+Acquire"
                        started = [started, label];
                    end
                    if type == "Acquire" || type == "Start+Acquire"
                        if label == ""
                            error("Invalid sequence, empty label for acquire command for camera %s.", camera)
                        end
                        if ~ismember(label, started)
                            error("Invalid sequence, acquire command before start command for camera %s.", camera)
                        end
                        if ismember(label, acquired)
                            error("Invalid sequence, label %s is acquired more than once for camera %s.", label, camera)
                        end
                        started(started == label) = [];
                        acquired(end + 1) = label;
                    end
                    if type == "Analysis"
                        if ~ismember(label, acquired)
                            error("Invalid sequence, missing acquire command for analysis on %s for camera %s.", label, camera)
                        end
                        if ismember(label, analyzed)
                            error("Invalid sequence, label %s is analyzed more than once for camera %s", label, camera)
                        end
                        analyzed(end + 1) = label;
                    end
                end
                if ~isempty(started)
                    error("Invalid sequence, missing acquire command for camera %s.", camera)
                end
            end
        end
    end

end

function sequence = makeSequence(cameras, labels, types, notes, empty_rows)
    arguments
        cameras = []
        labels = []
        types = []
        notes = []
        empty_rows = 2
    end
    num_command = length(cameras) + empty_rows;
    default_camera = "--inactive--";
    all_camera = ["Andor19330", "Andor19331", "Zelux", "--inactive--"];
    default_label = "";
    default_type = "Analysis";
    all_type = ["Start+Acquire", "Start", "Acquire", "Analysis"];
    default_note = "";
    Order = (1: num_command)';
    Camera = [cameras, repmat(default_camera, 1, empty_rows)]';
    Camera = categorical(Camera, all_camera, 'Ordinal', true);
    Label = [labels, repmat(default_label, 1, empty_rows)]';
    Type = [types, repmat(default_type, 1, empty_rows)]';
    Type = categorical(Type, all_type, 'Ordinal', true);
    Note = [notes, repmat(default_note, 1, empty_rows)]';
    sequence =  table(Order, Camera, Label, Type, Note);
end
