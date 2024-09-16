classdef AcquisitionConfig
    
    properties (SetAccess = {?Acquisitor})
        SequenceTable = table( ...
            (1:8)', ...
            categorical({'Zelux', 'Zelux', 'Andor19330', 'Andor19331', '--inactive--', '--inactive--', '--inactive--', '--inactive--'}, ...
            {'Andor19330', 'Andor19331', 'Zelux', '--inactive--'}, 'Ordinal', true)', ...
            ["Lattice", "DMD", "Image", "Image", "", "", "", ""]', ...
            ["", "", "", "", "", "", "", ""]', ...
            'VariableNames', {'Order', 'Camera', 'Label', 'Note'})
        NumAcquisitions = 20
        RefreshInterval = 0.01
        Timeout = Inf
    end

    properties (Dependent, Hidden)
        ActiveCameras
        ActiveSequence
        ActiveSequenceLength
    end

    methods

        function active_cameras = get.ActiveCameras(obj)
            active_cameras = unique(obj.SequenceTable.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"));
        end

        function active_sequence = get.ActiveSequence(obj)
            active_sequence = obj.SequenceTable(obj.SequenceTable.Camera ~= "--inactive--", :);
        end

        function sequence_length = get.ActiveSequenceLength(obj)
            sequence_length = height(obj.ActiveSequence);
        end
    end

end
