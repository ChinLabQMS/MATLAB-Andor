classdef LiveData < BaseObject
    
    properties (SetAccess = {?BaseObject})
        Raw
        Signal
        Background
        Noise
        Analysis
        Temporary
        RunNumber
        BadFrameDetected
    end

    properties (SetAccess = protected)
        LastData
    end

    properties (SetAccess = immutable)
        CameraManager
        Preprocessor
        Analyzer
    end
    
    % Shortcut to access properties of Analyzer
    properties (Dependent)
        LatCalib
        PSFCalib
        SiteCounters
    end

    methods
        function obj = LiveData(cameras, preprocessor, analyzer)
            arguments
                cameras = CameraManager()
                preprocessor = Preprocessor()
                analyzer = Analyzer()
            end
            obj.CameraManager = cameras;
            obj.Preprocessor = preprocessor;
            obj.Analyzer = analyzer;
            obj.reset()
        end

        function reset(obj)
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Noise = [];
            obj.Analysis = [];
            obj.Temporary = [];
            obj.RunNumber = 0;
            obj.BadFrameDetected = false;
            obj.LastData = [];
        end

        function init(obj)
            obj.LastData = obj.struct();
            obj.RunNumber = obj.RunNumber + 1;
            obj.BadFrameDetected = false;
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Noise = [];
            obj.Analysis = [];
            obj.Temporary = [];
        end

        function s = struct(obj)
            s = struct@BaseObject(obj, obj.VisibleProp);
            s.CameraManager = obj.CameraManager;
            s.Preprocessor = obj.Preprocessor;
            s.Analyzer = obj.Analyzer;
            s.LatCalib = obj.LatCalib;
            s.PSFCalib = obj.PSFCalib;
            s.SiteCounters = obj.SiteCounters;
        end

        function s = get.LatCalib(obj)
            s = obj.Analyzer.LatCalib;
        end

        function s = get.PSFCalib(obj)
            s = obj.Analyzer.PSFCalib;
        end

        function s = get.SiteCounters(obj)
            s = obj.Analyzer.SiteCounters;
        end
    end

end
