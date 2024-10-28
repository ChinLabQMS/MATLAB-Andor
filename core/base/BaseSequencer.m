classdef BaseSequencer < BaseObject

    properties (SetAccess = immutable)
        AcquisitionConfig
        CameraManager
        LayoutManager
        Preprocessor
        Analyzer
        DataManager
        StatManager
    end

    properties (SetAccess = protected)
        Timer
        RunNumber = 0
        Live
    end

    methods
        function obj = BaseSequencer(config, cameras, layouts, ...
                preprocessor, analyzer, data, stat)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager()
                layouts = []
                preprocessor = Preprocessor()
                analyzer = Analyzer(preprocessor)
                data = DataManager(config, cameras)
                stat = StatManager(config, cameras)
            end
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
            obj.LayoutManager = layouts;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.DataManager = data;
            obj.StatManager = stat;
        end
    end

end
