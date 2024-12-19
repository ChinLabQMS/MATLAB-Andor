classdef (Abstract) DataProcessor < BaseProcessor
    %BASEANALYZER Base class for single dataset analyzer.
    % The default behavior is to reload and preprocess the dataset if new 
    % DataPath is set. The processed data is stored in Signal property.
    
    properties (SetAccess = {?BaseObject})
        DataPath
    end
    
    properties (SetAccess = protected)
        Raw
        Signal
        Leakage
        Noise
    end

    methods
        function set.DataPath(obj, path)
            obj.loadData(path)
            obj.DataPath = path;
        end
    end

    methods (Access = protected, Hidden)
        function loadData(obj, path)
            obj.checkFilePath(path, 'DataPath')
            obj.Raw = load(path, "Data").Data;
            obj.info("Dataset loaded from '%s'", path)
            [obj.Signal, obj.Leakage, obj.Noise] = Preprocessor().process(obj.Raw);
        end

        function init(obj)
            obj.assert(~isempty(obj.DataPath), 'DataPath is unset!')
        end
    end
    
end
