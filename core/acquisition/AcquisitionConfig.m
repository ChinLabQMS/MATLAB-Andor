classdef AcquisitionConfig < BaseObject
    
    properties (SetAccess = {?BaseRunner})
        SequenceTable {SequenceRegistry.mustBeValidSequence} = SequenceRegistry.Full4Analysis
        NumAcquisitions (1, 1) double = 20
        NumStatistics (1, 1) double = 2000
        Refresh (1, 1) double = 0.01
        Timeout (1, 1) double = Inf
    end

    properties (Dependent, Hidden)
        ActiveCameras
        ActiveSequence
        ActiveAcquisition
        ActiveAnalysis
        ImageList
    end

    methods
        function contents = parseAnalysis2Content(obj, index_str)
            res = split(index_str, ": ");
            [camera, label] = res{:};
            active_analysis = obj.ActiveAnalysis;
            seq = active_analysis(active_analysis.Camera == camera & active_analysis.Label == label, :);
            if height(seq) == 1
                [~, out_vars] = AnalysisRegistry.parseAnalysisOutput(seq.Note);
                contents = ("Analysis: " + out_vars')';
            else
                contents = string.empty;
            end
        end

        function list_str = get.ImageList(obj)
            active_acquisition = obj.ActiveAcquisition;
            num_images = height(active_acquisition);
            list_str = cell(num_images, 1);
            for i = 1:num_images
                camera = string(active_acquisition.Camera(i));
                label = string(active_acquisition.Label(i));
                list_str{i} = sprintf('%s: %s', camera, label);
            end
        end

        function active_cameras = get.ActiveCameras(obj)
            active_cameras = unique(obj.SequenceTable.Camera);
            active_cameras = string(active_cameras(active_cameras ~= "--inactive--"))';
        end

        function active_sequence = get.ActiveSequence(obj)
            active_sequence = obj.SequenceTable( ...
                obj.SequenceTable.Camera ~= "--inactive--" & ~(obj.SequenceTable.Type == "Analysis" & obj.SequenceTable.Note == ""), :);
        end

        function active_acquisition = get.ActiveAcquisition(obj)
            active_sequence = obj.ActiveSequence;
            active_acquisition = active_sequence(active_sequence.Type == "Acquire" | active_sequence.Type == "Start+Acquire", :);
        end

        function active_analysis = get.ActiveAnalysis(obj)
            active_sequence = obj.ActiveSequence;
            active_analysis = active_sequence(active_sequence.Type == "Analysis" & active_sequence.Note ~= "", :);
        end

        function disp(obj)
            disp@BaseObject(obj)
            disp(obj.SequenceTable)
        end
    end
    
    methods (Static)
        function obj = struct2obj(s)
            obj = BaseRunner.struct2obj(s, AcquisitionConfig());
        end
    end

end
