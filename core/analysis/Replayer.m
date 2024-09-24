classdef Replayer < BaseObject

    properties (SetAccess = immutable, Hidden)
        Data
        Stat
        Preprocessor
        Analyzer
    end

    methods
        function obj = Replayer(filename)
            obj.Data = Dataset.file2obj(filename);
            obj.Stat = StatResult();
            obj.Preprocessor = Preprocessor();
            obj.Analyzer = Analyzer();
        end
    end

end
