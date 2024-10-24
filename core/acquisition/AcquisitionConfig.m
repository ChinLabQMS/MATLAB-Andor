classdef AcquisitionConfig < BaseObject
    
    properties (SetAccess = {?BaseObject})
        SequenceTable {SequenceRegistry.mustBeValidSequence} = SequenceRegistry.Full4Analysis
        NumAcquisitions = 20
        NumStatistics = 2000
        Refresh = 0.01
        Timeout = Inf
        DropBadFrames = true
        AbortAtEnd = true
    end
    
    % Properties that updates with SequenceTable
    properties (SetAccess = protected)
        ImageList
        ActiveCameras
        ActiveSequence
        ActiveAcquisition
        ActiveAnalysis
        AcquisitionParams
        AnalysisProcesses
        AnalysisOutVars
        AnalysisOutData
    end

    methods
        function obj = AcquisitionConfig()
            obj.SequenceTable = obj.SequenceTable;
        end

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
            obj.SequenceTable = sequence_table;
            obj.updateProp()
        end

        % Override the default prop method from BaseObject
        function list = prop(~)
            list = ["SequenceTable", "NumAcquisitions", "NumStatistics", "Refresh", "Timeout"];
        end

        function disp(obj)
            disp@BaseObject(obj)
            disp(obj.SequenceTable)
        end
    end

    methods (Access = protected, Hidden)
        function updateProp(obj)
            active_cameras = unique(obj.SequenceTable.Camera);
            obj.ActiveCameras = string(active_cameras(active_cameras ~= "--inactive--"))';
            obj.ActiveSequence = obj.SequenceTable( ...
                obj.SequenceTable.Camera ~= "--inactive--" & ~(obj.SequenceTable.Type == "Analysis" & obj.SequenceTable.Note == ""), :);
            obj.ActiveAcquisition = obj.ActiveSequence((obj.ActiveSequence.Type == "Acquire") | (obj.ActiveSequence.Type == "Start+Acquire"), :);
            obj.ActiveAnalysis = obj.ActiveSequence(obj.ActiveSequence.Type == "Analysis" & obj.ActiveSequence.Note ~= "", :);
            
            active_acquisition = obj.ActiveAcquisition;
            num_images = height(active_acquisition);
            list_str = cell(num_images, 1);
            for i = 1:num_images
                camera = string(active_acquisition.Camera(i));
                label = active_acquisition.Label(i);
                note = active_acquisition.Note(i);
                list_str{i} = sprintf('%s: %s', camera, label);
                obj.AcquisitionParams.(camera).(label) = parseString2Args(note, "output_format", "cell");
            end
            obj.ImageList = list_str;

            active_analysis = obj.ActiveAnalysis;
            for i = 1:height(active_analysis)
                camera = string(active_analysis.Camera(i));
                label = active_analysis.Label(i);
                note = active_analysis.Note(i);
                [obj.AnalysisProcesses.(camera).(label), obj.AnalysisOutVars.(camera).(label), ...
                    obj.AnalysisOutData.(camera).(label)] = AnalysisRegistry.parseOutput(note);
            end
        end
    end
    
    methods (Static)
        function obj = struct2obj(s, varargin)
            obj = BaseRunner.struct2obj(s, AcquisitionConfig(), varargin{:});
        end
    end

end
