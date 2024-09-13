classdef AcquisitionConfig
    
    properties (SetAccess = {?Acquisitor})
        SequenceTable = table( ...
            categorical({'Zelux', 'Zelux', 'Andor19330', 'Andor19331'}, {'Andor19330', 'Andor19331', 'Zelux', '--inactive--'}, 'Ordinal', true)', ...
            ["Lattice", "DMD", "Image", "Image"]', ...
            ["", "", "", ""]', ...
            'VariableNames', {'Camera', 'Label', 'Note'})
        NumAcquisitions = 20
        RefreshInterval = 0.01
        Timeout = Inf
    end

end
