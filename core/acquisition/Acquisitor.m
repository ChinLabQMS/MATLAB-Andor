classdef Acquisitor < BaseSequencer

    % Class properties that control the live acquisition behaviors
    properties (Constant)
        Run_VerboseStart = false
        Run_VerboseAcquire = true
        Run_VerbosePreprocess = false
        Run_VerboseAnalysis = false
    end

    methods
        function obj = Acquisitor(varargin)
            obj@BaseSequencer(varargin{:})
        end

        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.AcquisitionConfig.ActiveCameras)
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.DataManager.init()
            obj.StatManager.init()
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Acquisition initialized.")
        end
    end

    methods (Access = protected)
    end

end
