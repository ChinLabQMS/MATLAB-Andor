classdef Acquisitor < handle

    properties (SetAccess = private)
        % Status - The current status of the acquisition
        %   Idle - The acquisition is ready to be started
        %   Running - The acquisition is currently running
        %   Paused - The acquisition is paused
        %   Stopped - The acquisition has been stopped
        Status (1, 1) string {mustBeMember(Status, ["Idle", "Running", "Paused", "Stopped"])} = "Stopped"
        CurrentIndex (1, 1) double {mustBeInteger, mustBePositive} = 1
        AcquisitionConfig (1, 1) AcquisitionConfig
        Data (1, 1) struct
        CameraSetting (1, 1) struct
    end
    
    methods
        function obj = Acquisitor()
        end

        function runAcquisition(obj)
            % Run a single acquisition sequence
            obj.Status = "Running";
        end
    end
end
