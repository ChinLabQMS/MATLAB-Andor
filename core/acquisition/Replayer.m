classdef Replayer < BaseRunner

    properties (SetAccess = immutable, Hidden)
        Preprocessor
        Analyzer
        Stat
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
            try
                obj.Data = load(obj.Config.Filepath, "Data").Data;
            catch
                
            end
        end
    end

end
