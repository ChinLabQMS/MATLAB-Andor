classdef Acquisitor < handle
    
    properties (SetAccess = {?AcquisitionApp})
        % Status - The current status of the acquisitor, can be one of the following:
        %   - Idle: The acquisitor is not running and configured to run
        %   - Running: The acquisitor is currently running
        %   - Paused: The acquisitor is paused
        %   - Stopped: The acquisitor is stopped, may be reconfigured
        Status (1, 1) string {mustBeMember(Status, ["Idle", "Running", "Paused", "Stopped"])} = "Stopped"
    end

    properties (SetAccess = private)
        CurrentIndex (1, 1) double {mustBeInteger, mustBePositive} = 1
        AcquisitionConfig (1, 1) AcquisitionConfig
        Data (1, 1) Dataset
        Cameras (1, 1) struct = struct()
    end
    
    methods
        function obj = Acquisitor(config)
            obj.AcquisitionConfig = config;
        end

        function runAcquisition(obj)
            % Run a single acquisition sequence
            obj.Status = "Running";
        end
    end
end
