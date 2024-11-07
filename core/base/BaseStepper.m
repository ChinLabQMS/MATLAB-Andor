classdef BaseStepper < BaseObject

    properties (SetAccess = immutable)
        Sequencer
        CameraName
        ImageLabel
        OperationNote
    end

    properties (SetAccess = protected)
        RunParams
    end

    methods
        function obj = BaseStepper(sequencer, camera, label, note, varargin)
            obj.Sequencer = sequencer;
            obj.CameraName = camera;
            obj.ImageLabel = label;
            obj.OperationNote = note;
            obj.RunParams = [obj.getDefaultParams(), obj.parseRunParams(note, varargin{:})];
        end

        function run(~)
        end
    end

    methods (Access = protected)
        function params = getDefaultParams(obj)
            params = {"label", obj.ImageLabel};
        end

        function params = parseRunParams(obj, note, options)
            arguments
                obj
                note
                options.full = true
                options.composite_name = "Start"
                options.process_list = ["Start", "Acquire", "Preprocess"]
            end
            if options.full
                params = obj.parseString2Args(note);
            else
                params = obj.parseString2Processes(note, options.process_list, ...
                "full_struct", true).(options.composite_name);
            end
        end
    end

    methods (Access = protected, Hidden, Sealed)
        % Split structure of arguments by processes names, return a
        % structure of cell array
        function [processes, overall] = parseString2Processes(obj, note, process_list, options)
            arguments
                obj
                note
                process_list
                options.full_struct = false
                options.include_overall = false
            end
            args = parseString2Args(obj, note);
            curr = [];
            processes = struct();
            overall = {};
            for i = 1: 2: length(args)
                name = args{i};
                value = args{i + 1};
                if ismember(name, process_list) && value
                    % Start a new process
                    curr = name;
                    processes.(curr) = {};
                elseif ~isempty(curr)
                    % Parse the arguments as parameter of current process
                    processes.(curr) = [processes.(curr), {name, value}];
                elseif options.include_overall
                    overall = [overall, {name, value}];
                else
                    obj.error("Unable to parse argument name '%s', no identifier before parameters.", name)
                end
            end
            if options.full_struct
                for p = process_list
                    if ~isfield(processes, p)
                        processes.(p) = {};
                    end
                end
            end
        end

        % Parse the note to a cell array of name-value pairs
        function args = parseString2Args(obj, note)
            % Erase white-space and split the string by ","
            pieces = split(erase(note, " "), ",")';
            pieces = pieces(pieces ~= "");
            % For each string piece, try to parse as name=value
            args = cell(1, 2 * length(pieces));
            for i = 1: length(pieces)
                p = pieces(i);
                if contains(p, "=")
                    vals = split(p, "=");
                    if length(vals) == 2
                        args{2*i-1} = vals(1);
                        arg_val = double(string(vals(2)));
                        if isnan(arg_val) && ~ismember(vals(2), ["Nan", "NaN", "nan"])
                            args{2*i} = vals(2);
                        else
                            args{2*i} = arg_val;
                        end
                    else
                        obj.error("Multiple '=' appears in the partitioned string '%s'.", p)
                    end
                elseif p ~= ""
                    args{2*i-1} = p;
                    args{2*i} = true;
                end
            end
        end
    end

end
