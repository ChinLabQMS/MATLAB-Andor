classdef Acquisitor < BaseSequencer

    methods
        function obj = Acquisitor(varargin)
            obj@BaseSequencer(varargin{:})
        end

        % Initialize acquisition
        function init(obj)
            obj.CameraManager.init(obj.AcquisitionConfig.ActiveCameras)
            obj.DataStorage.init()
            obj.StatStorage.init()
            if ~isempty(obj.LayoutManager)
                obj.LayoutManager.init()
            end
            obj.Timer = tic;
            obj.RunNumber = 0;
            obj.info2("Acquisition initialized.")
        end
        
        % Configure the acquisition to a data
        function config(obj, data)
            obj.AcquisitionConfig.config(data.AcquisitionConfig)
            obj.CameraManager.config(data)
            obj.DataStorage.config(data, "config_cameras", false, "config_acq", false)
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

        function addData(obj, verbose)
            obj.DataStorage.add(obj.Live.Raw, "verbose", verbose);
        end

        function abortAtEnd(obj)
            obj.CameraManager.abortAcquisition(obj.AcquisitionConfig.ActiveCameras)
        end
    end

end
