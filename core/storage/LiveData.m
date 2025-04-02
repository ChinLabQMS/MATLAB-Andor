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
        LatCalib
        PSFCalib
        SiteCounters
    end

    methods
        function obj = LiveData(cameras, lat_calib, psf_calib, counters)
            arguments
                cameras = CameraManager()
                lat_calib = []
                psf_calib = []
                counters = []
            end
            obj.CameraManager = cameras;
            obj.LatCalib = lat_calib;
            obj.PSFCalib = psf_calib;
            obj.SiteCounters = counters;
            obj.reset()
        end

        function reset(obj)
            obj.LastData = [];
            obj.RunNumber = 0;
            obj.BadFrameDetected = false;
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Noise = [];
            obj.Analysis = [];
            obj.Temporary = [];
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
            s.LatCalib = obj.LatCalib;
            s.PSFCalib = obj.PSFCalib;
        end
    end

end
