classdef AnalysisStepper < BaseStepper
    
    methods
        function run(obj)
            analysis = obj.Sequencer.Analyzer.analyze(obj.Sequencer.Live, obj.RunParams{:});
            if isfield(obj.Live.Analysis, obj.CameraName) && isfield(obj.Live.Analysis.(obj.CameraName), obj.ImageLabel)
                for name = string(fields(analysis))'
                    obj.Live.Analysis.(obj.CameraName).(obj.ImageLabel).(name) = analysis.(name);
                end
            else
                obj.Live.Analysis.(obj.CameraName).(obj.ImageLabel) = analysis;
            end
        end
    end

    methods (Access = protected)
        function params = getDefaultParams(obj)
            params = {"camera", obj.CameraName, ...
                      "label", obj.ImageLabel, ...
                      "config", obj.Sequencer.CameraManager.(obj.CameraName).Config};
        end

        function params = parseRunParams(obj, note)
            [~, analysis_list] = enumeration('AnalysisRegistry');
            [processes, overall] = obj.parseString2Processes(note, analysis_list, "include_overall", true);
            process_names = string(fields(processes))';
            process_params = cell(1, length(process_names));
            for i = 1:length(process_names)
                p = process_names(i);
                process_params{i} = [{AnalysisRegistry.(p).FuncHandle}, processes.(p)];
            end
            params = [{"processes", process_params}, overall];
        end
    end

end
