function is_valid = mustBeValidSequence(sequence_table)
    arguments
        sequence_table (:, 5) table
    end
    active_cameras = unique(sequence_table.Camera);
    active_cameras = string(active_cameras(active_cameras ~= "--inactive--"))';
    is_valid = true;
    for camera = active_cameras
        camera_seq = sequence_table(sequence_table.Camera == camera, :);
        started = false;
        acquired = string.empty;
        for i = 1:height(camera_seq)
            label = string(camera_seq.Label(i));
            type = string(camera_seq.Type(i));
            if type == "Start" || type == "Start+Acquire"
                if started
                    warning("Invalid sequence, multiple start commands before acquire for camera %s.", camera)
                    is_valid = false;
                    return
                end
                started = true;
            end
            if type == "Acquire" || type == "Start+Acquire"
                if ~started
                    warning("Invalid sequence, acquire command before start command for camera %s.", camera)
                    is_valid = false;
                    return
                end
                if any(acquired == label)
                    warning("Invalid sequence, label %s is acquired more than once for camera %s.", label, camera)
                    is_valid = false;
                    return
                end
                if label == ""
                    warning("Invalid sequence, empty label for acquire command for camera %s.", camera)
                    is_valid = false;
                    return
                end
                started = false;
                acquired(end + 1) = label; %#ok<AGROW>
            end
            if type == "Analysis"
                if ~any(acquired == label)
                    warning("Invalid sequence, missing acquire command for analysis on %s for camera %s.", label, camera)
                    is_valid = false;
                    return
                end
            end
        end
        if started
            warning("Invalid sequence, missing acquire command for camera %s.", camera)
        end
    end
end
