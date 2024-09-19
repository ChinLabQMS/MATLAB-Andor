classdef Preprocessor < BaseObject 

    properties
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseObject(config);
        end
        
    end

    methods (Access = protected)
        function runLoadBackground(obj, params)
            % Load background image
            obj.Background = load(params.file);
        end

        function runBackroundSubstraction(obj, params)

        end

        function runOffsetCorrection(obj, params)
        end
    end
end
