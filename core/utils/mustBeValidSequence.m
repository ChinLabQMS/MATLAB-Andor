function mustBeValidSequence(sequence_table)
    arguments
        sequence_table (:, 5) table
    end
    active_cameras = unique(sequence_table.Camera);
    active_cameras = string(active_cameras(active_cameras ~= "--inactive--"))';
    if isempty(active_cameras)
        error("Invalid sequence, no active camera.")
    end
    for camera = active_cameras
        camera_seq = sequence_table(sequence_table.Camera == camera, :);
        started = false;
        acquired = string.empty;
        analyzed = string.empty;
        for i = 1:height(camera_seq)
            label = string(camera_seq.Label(i));
            type = string(camera_seq.Type(i));
            if type == "Start" || type == "Start+Acquire"
                if started
                    error("Invalid sequence, multiple start commands before acquire for camera %s.", camera)
                end
                started = true;
            end
            if type == "Acquire" || type == "Start+Acquire"
                if ~started
                    error("Invalid sequence, acquire command before start command for camera %s.", camera)
                end
                if any(acquired == label)
                    error("Invalid sequence, label %s is acquired more than once for camera %s.", label, camera)
                end
                if label == ""
                    error("Invalid sequence, empty label for acquire command for camera %s.", camera)
                end
                started = false;
                acquired(end + 1) = label; %#ok<AGROW>
            end
            if type == "Analysis"
                if ~any(acquired == label)
                    error("Invalid sequence, missing acquire command for analysis on %s for camera %s.", label, camera)
                end
                if any(analyzed == label)
                    error("Invalid sequence, label %s is analyzed more than once for camera %s", label, camera)
                end
                note = camera_seq.Note(i);
                parseAnalysisOutput(note);
                analyzed(end + 1) = label; %#ok<AGROW>
            end
        end
        if started
            error("Invalid sequence, missing acquire command for camera %s.", camera)
        end
    end
end
