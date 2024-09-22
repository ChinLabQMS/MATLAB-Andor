classdef Preprocessor < BaseAnalyzer

    properties (SetAccess = protected, Transient)
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseAnalyzer(config);
        end

        function initLoadBackground(obj)
            % Load background image
            file = obj.Config.LoadBackgroundParams.file;
            obj.Background = load(file);
        end

        function data = runBackroundSubstraction(obj, data)
            
        end

        function data = runOffsetCorrection(obj, data)
        end
    end
end
