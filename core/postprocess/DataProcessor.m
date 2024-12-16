classdef (Abstract) DataProcessor < BaseProcessor
    %BASEANALYZER Base class for single dataset analyzer.
    % The default behavior is to reload and preprocess the dataset if new 
    % DataPath is set. The processed data is stored in Signal property.
    
    properties (SetAccess = {?BaseObject})
        DataPath
    end
    
    properties (SetAccess = protected)
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

    methods (Access = protected, Sealed, Hidden)
        function loadData(obj, path)
            obj.checkFilePath(path, 'DataPath')
            Data = load(path, "Data").Data;
            obj.info("Dataset loaded from '%s'", path)
            [obj.Signal, obj.Leakage, obj.Noise] = Preprocessor().process(Data);
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            if isempty(obj.DataPath)
                obj.error('DataPath unset!')
            end
        end
    end
    
end
