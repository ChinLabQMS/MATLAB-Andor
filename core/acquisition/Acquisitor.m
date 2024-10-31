classdef Acquisitor < BaseSequencer

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

    methods (Access = protected, Hidden)
        function startAcquisition(obj, info, varargin)
            obj.CameraManager.(info.camera).startAcquisition(varargin{:})
        end
        
        function acquireImage(obj, info, varargin)
            [obj.Live.Raw.(info.camera).(info.label), status] = obj.CameraManager.(info.camera).acquire(info, varargin{:});
            if status ~= "good"
                obj.BadFrameDetected = true;
            end
        end
    end

end
