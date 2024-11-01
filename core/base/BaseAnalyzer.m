classdef (Abstract) BaseAnalyzer < BaseProcessor
    %BASEANALYZER Base class for single dataset analyzer.
    % The default behavior is to reload and preprocess the dataset if new 
    % DataPath is set. The processed data is stored in Signal property.
    
    properties (SetAccess = {?BaseObject})
        DataPath % "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
    end
    
    properties (SetAccess = protected)
        Signal
    end

    methods
        function set.DataPath(obj, path)
            obj.DataPath = path;
            obj.loadData()
        end
    end

    methods (Access = protected, Sealed, Hidden)
        function loadData(obj)
            if isempty(obj.DataPath)
                return
            end
            Data = load(obj.DataPath, "Data").Data;
            obj.info("Dataset loaded from '%s'", obj.DataPath)
            obj.Signal = Preprocessor().process(Data);
        end
    end
    
end
