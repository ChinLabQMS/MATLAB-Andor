classdef AcquisitionConfig
    
    properties (SetAccess = {?Acquisitor})
        SequenceTable = table( ...
            (1:8)', ...
            categorical({'Zelux', 'Zelux', 'Andor19330', 'Andor19331', 'Andor19330', 'Andor19331', '--inactive--', '--inactive--'}, ...
            {'Andor19330', 'Andor19331', 'Zelux', '--inactive--'}, 'Ordinal', true)', ...
            ["Lattice", "DMD", "Image", "Image", "Image", "Image", "", ""]', ...
            categorical({'Full', 'Full', 'Start', 'Start', 'Acquire', 'Acquire', 'Full', 'Full'}, ...
            {'Full', 'Start', 'Acquire'}, 'Ordinal', true)', ...
            ["", "", "", "", "", "", "", ""]', ...
            'VariableNames', {'Order', 'Camera', 'Label', 'Type', 'Note'})
        NumAcquisitions = 20
        Refresh = 0.01
        Timeout = Inf
    end

    properties (Dependent, Hidden)
        ActiveCameras
        ActiveSequence
        ActiveAcquisition
    end

    methods

        function obj = set.SequenceTable(obj, sequence_table)
            if obj.checkSequence(sequence_table)
                obj.SequenceTable = sequence_table;
            else
                error("Invalid sequence table.")
            end
        end

        function active_cameras = get.ActiveCameras(obj)
            active_cameras = unique(obj.SequenceTable.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"));
        end

        function active_sequence = get.ActiveSequence(obj)
            active_sequence = obj.SequenceTable(obj.SequenceTable.Camera ~= "--inactive--", :);
        end

        function active_acquisition = get.ActiveAcquisition(obj)
            active_sequence = obj.ActiveSequence;
            active_acquisition = active_sequence(active_sequence.Type ~= "Start", :);
        end

    end

    methods (Hidden)

        function valid = checkSequence(obj, sequence_table)
            arguments
                obj
                sequence_table (:, 5) table
            end
            active_cameras = unique(sequence_table.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"));
            for camera = active_cameras
                subsequence = sequence_table(sequence_table.Camera == camera, :);
                start = 0;
                for i = 1:height(subsequence)
                    switch subsequence.Type(i)
                        case "Start"
                            if start == 1
                                valid = false;
                                return
                            end
                            start = start + 1; 
                        case "Acquire"
                            if start == 0
                                valid = false;
                                return
                            end
                            start = start - 1;
                        case "Full"
                    end
                end
            end
            valid = true;
        end
        
    end

end
