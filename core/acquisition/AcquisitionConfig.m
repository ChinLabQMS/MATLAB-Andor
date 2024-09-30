classdef AcquisitionConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        SequenceTable {mustBeValidSequence} = SequenceRegistry.Sequence4Basic
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
        ListOfImages
    end

    methods
        function contents = parseAnalysis(obj, index_str)
            res = split(index_str, ": ");
            [camera, label] = res{:};
            active_analysis = obj.ActiveAnalysis;
            seq = active_analysis(active_analysis.Camera == camera & active_analysis.Label == label, :);
            if height(seq) == 1
                [~, out_vars] = parseAnalysisOutput(seq.Note);
                contents = arrayfun(@(x) "Analysis: " + x, out_vars);
            else
                contents = string.empty;
            end
        end

        function index_str = findIndex(obj, ax_name)
            active_acquisition = obj.ActiveAcquisition;
            seq = active_acquisition(contains(active_acquisition.Note, ax_name), :);
            if height(seq) == 1
                index_str = sprintf("%s: %s", seq.Camera, seq.Label);
            else
                index_str = string.empty;
            end
        end

        function list = get.ListOfImages(obj)
            active_acquisition = obj.ActiveAcquisition;
            num_images = height(active_acquisition);
            list = cell(num_images, 1);
            for i = 1:num_images
                camera = string(active_acquisition.Camera(i));
                label = string(active_acquisition.Label(i));
                list{i} = sprintf('%s: %s', camera, label);
            end
        end

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
            obj = BaseObject.struct2obj(s, AcquisitionConfig());
        end

        function obj = file2obj(filename)
            obj = BaseObject.file2obj(filename, AcquisitionConfig());
        end
    end

end
