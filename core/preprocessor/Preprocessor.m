classdef Preprocessor < handle
    
    properties (SetAccess = immutable)
        PreprocessConfig
    end

    properties (Dependent, Hidden)
        CurrentLabel
    end
    
    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj.PreprocessConfig = config;
        end

        function init(obj)

        end

        function run(obj)
            sequence = obj.PreprocessConfig.Sequence;
            for i = 1:length(sequence)
                step = sequence(i);
                switch step
                    case "BackgroundSubtraction"
                        obj.runBackroundSubstraction();
                    case "OffsetCorrection"
                        obj.runOffsetCorrection();
                end
            end
        end
        
        function runBackroundSubstraction(obj)
        end

        function runOffsetCorrection(obj)
        end

        function label = get.CurrentLabel(obj)
            label = sprintf("[%s] %s", datetime('now', 'Format', 'HH:mm:ss'), class(obj));
        end

    end
end
