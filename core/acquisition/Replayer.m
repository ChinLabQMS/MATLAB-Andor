classdef Replayer < BaseSequencer
    
    methods
        function init(obj)
        end
    end

    methods (Access = protected, Hidden)
        % Override the default behavior in BaseProcessor
        function applyConfig(obj)
            obj.DataManager = DataManager.struct2obj( ...
                load(obj.Config.DataPath, "Data").Data, ...
                obj.AcquisitionConfig, ...
                obj.CameraManager, ...
                "test_mode", obj.Config.TestMode);
            obj.StatManager = StatManager(obj.AcquisitionConfig);
            obj.StatManager.init()
            obj.CurrentIndex = 0;
            obj.info("Dataset loaded from:\n\t'%s'.", obj.Config.DataPath)
        end

        function startAcquisition(~, ~, varargin)
        end
        
        function acquireImage(obj, info, varargin)
            obj.CameraManager.(info.camera).acquire(info, varargin{:});
        end
    end

end
