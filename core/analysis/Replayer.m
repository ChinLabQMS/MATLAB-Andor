classdef Replayer < BaseRunner

    properties (SetAccess = immutable, Hidden)
        Preprocessor
        Analyzer
    end

    properties (SetAccess = protected, Hidden)
        Data
        Stat
    end

    methods
        function obj = Replayer(config)
            obj.Preprocessor = Preprocessor();
            obj.Analyzer = Analyzer();
        end

        function init(obj, data_struct)
            obj.Data = data_struct;
        end

        function preprocess(obj)

        end

        function analyze(obj)
        end
    end

end
