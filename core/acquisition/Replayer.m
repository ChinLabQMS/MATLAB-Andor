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
        function obj = Replayer(config)
            arguments
                config (1, 1) ReplayerConfig = ReplayerConfig()
            end
            obj@BaseRunner(config)
            obj.Preprocessor = Preprocessor();
            obj.Analyzer = Analyzer();
        end

        function init(obj)
            obj.Data = load(obj.Config.DataPath, "Data").Data;
            obj.Preprocessor.init()
            obj.Analyzer.init()
        end
    end

end
