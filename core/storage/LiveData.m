classdef LiveData < BaseObject
    
    properties (SetAccess = {?BaseObject})
        Raw
        Signal
        Background
        Noise
        Analysis
        Temporary
        RunNumber = 0
        BadFrameDetected = false
    end

    properties (SetAccess = protected)
        LastData
    end

    properties (SetAccess = immutable)
        CameraManager
        LatCalib
        PSFCalib
    end

    methods
        function obj = LiveData(cameras, lat_calib, psf_calib)
            arguments
                cameras = CameraManager()
                lat_calib = []
                psf_calib = []
            end
            obj.CameraManager = cameras;
            obj.LatCalib = lat_calib;
            obj.PSFCalib = psf_calib;
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
            s = struct@BaseObject(obj);
            s.CameraManager = obj.CameraManager;
            s.LatCalib = obj.LatCalib;
            s.PSFCalib = obj.PSFCalib;
        end
    end

end
