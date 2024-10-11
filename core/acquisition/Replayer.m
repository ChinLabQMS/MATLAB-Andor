classdef Replayer < BaseRunner

    properties (SetAccess = immutable, Hidden)
        LayoutManager
        Stat
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected, Hidden)
        Data
    end

    methods
        function obj = Replayer(preprocessor, analyzer, config)
            arguments
                preprocessor (1, 1) Preprocessor = Preprocessor()
                analyzer (1, 1) Analyzer = Analyzer(preprocessor)
                config (1, 1) ReplayerConfig = ReplayerConfig()
            end
            obj@BaseRunner(config)
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
        end

        function init(obj)
            obj.Data = load(obj.Config.DataPath, "Data").Data;
        end
    end

end
