classdef AnalysisStepper < BaseStepper
    
    methods
        function run(obj, verbose)

        end
    end

    methods (Access = protected)
        function params = parseRunParams(obj, note)
            [~, analysis_list] = enumeration('AnalysisRegistry');
            args = obj.parseString2Processes(note, analysis_list);
            process_names = string(fields(args))';
            params = cell(1, length(process_names));
            for i = 1:length(process_names)
                p = process_names(i);
                params{i} = [{AnalysisRegistry.(p).FuncHandle}, args.(p)];
            end
        end
    end

end
