classdef AcquisitionConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        SequenceTable {mustBeValidSequence} = SequenceExample.Sequence4Basic
        NumAcquisitions (1, 1) double = 20
        Refresh (1, 1) double = 0.01
        Timeout (1, 1) double = Inf
    end

    properties (Dependent, Hidden)
        ActiveCameras
        ActiveSequence
        ActiveAcquisition
    end

    methods
        function active_cameras = get.ActiveCameras(obj)
            active_cameras = unique(obj.SequenceTable.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"))';
        end

        function active_sequence = get.ActiveSequence(obj)
            active_sequence = obj.SequenceTable(obj.SequenceTable.Camera ~= "--inactive--", :);
        end

        function active_acquisition = get.ActiveAcquisition(obj)
            active_sequence = obj.ActiveSequence;
            active_acquisition = active_sequence(active_sequence.Type == "Acquire" | active_sequence.Type == 'Start+Acquire', :);
        end

        function disp(obj)
            disp@BaseObject(obj)
            disp(obj.SequenceTable)
        end
    end
    
    methods (Static)
        function obj = struct2obj(s)
            obj = BaseObject.struct2obj(s, AcquisitionConfig());
        end

        function obj = file2obj(filename)
            obj = BaseObject.file2obj(filename, AcquisitionConfig());
        end
    end

end
