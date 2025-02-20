classdef (Abstract) BaseStorage < BaseObject
    %BASESTORAGE Base class for storage objects. 
    % This class is used to store data/analysis results, providing a common
    % interface for saving/loading data and exporting to other formats, as well
    % as for checking the current index and memory usage of the storage object.
    
    % Properties for storing data
    properties (SetAccess = {?BaseObject})
        Andor19330
        Andor19331
        Zelux
        DMD
        Picomotor
    end
    
    % Handles to track acquisition settings
    properties (SetAccess = immutable)
        AcquisitionConfig
        CameraManager
    end
    
    % Live data for recording status
    properties (SetAccess = protected)
        CurrentIndex
        MaxIndex
    end

    properties (Abstract, SetAccess = immutable)
        MaxIndexProp
    end

    properties (Dependent, Hidden)
        MemoryUsage
    end

    methods
        function obj = BaseStorage(config, cameras)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager('test_mode', 1)
            end
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
        end

        function usage = get.MemoryUsage(obj)
            obj.checkInitialized()
            s = obj.struct("check_incomplete", false, "completed_only", false); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end
    end

    methods (Sealed)    
        % Override struct in BaseObject
        function s = struct(obj, options)
            arguments
                obj
                options.check_incomplete = true
                options.completed_only = true
            end
            obj.checkInitialized()
            if options.check_incomplete && (obj.CurrentIndex < obj.MaxIndex)
                if options.completed_only
                    obj.warn("Incomplete dataset (%d / %d), only completed data is saved.", ...
                        obj.CurrentIndex, obj.MaxIndex)
                else
                    obj.warn("Incomplete dataset (%d / %d).", ...
                        obj.CurrentIndex, obj.MaxIndex)
                end
            end
            s.AcquisitionConfig = obj.AcquisitionConfig.struct();
            if options.completed_only && (obj.CurrentIndex < obj.MaxIndex)
                s.AcquisitionConfig.(obj.MaxIndexProp) = obj.CurrentIndex;
            end
            for camera = obj.ConfigurableProp
                if isempty(obj.(camera))
                    continue
                end
                s.(camera) = obj.(camera);
                % Remove the data that is not yet acquired.
                if options.completed_only && (obj.CurrentIndex < obj.MaxIndex)
                    for label = string(fields(s.(camera)))'
                        if label == "Config"
                            if isfield(s.(camera).Config, "DataTimestamp")
                                s.(camera).Config.DataTimestamp = s.(camera).Config.DataTimestamp(1: obj.CurrentIndex);
                            end
                        else
                            s.(camera).(label) = obj.removeIncomplete(s.(camera).(label));
                        end
                    end
                end
            end
        end
        
        function initMaxIndex(obj)
            obj.MaxIndex = obj.AcquisitionConfig.(obj.MaxIndexProp);
        end

        % Initialize the storage to the acquisition and camera config
        function init(obj)
            obj.CurrentIndex = 0;
            obj.initMaxIndex();
            for device = obj.ConfigurableProp
                obj.(device) = [];
            end
            for device = obj.AcquisitionConfig.ActiveDevices
                controller = obj.CameraManager.(device);
                if isa(controller, "Camera")
                    % Record camera config
                    obj.(device).Config = obj.CameraManager.(device).Config.struct();
                    % Record some additional information to the camera config
                    obj.(device).Config.CameraName = device;
                    obj.(device).Config.AcquisitionNote = obj.AcquisitionConfig.AcquisitionNote.(device);
                    obj.(device).Config.DataTimestamp = NaT(obj.MaxIndex, 1);
                    labels = string(fields(obj.(device).Config.AcquisitionNote))';
                    obj.initAcquisitionStorage(device, labels)
                elseif isa(controller, "Projector")
                    obj.(device).Config = obj.CameraManager.(device).struct();
                    obj.(device).Config.ProjectorName = device;
                    obj.(device).Config.ProjectionNote = obj.AcquisitionConfig.ProjectionNote.(device);
                elseif isa(controller, "PicomotorDriver")
                    obj.(device).Config.DriverName = device;
                    for ii = 1: 4
                        obj.(device).Config.("Picomotor" + string(ii)) = controller.("Picomotor" + string(ii)).TargetPosition;
                    end
                    obj.(device).Config.MotionNote = obj.AcquisitionConfig.MotionNote.(device);
                else
                    obj.error('Unrecongnized device type for %s: %s!', device, class(controller))
                end
                if isfield(obj.AcquisitionConfig.AnalysisNote, device)
                    obj.(device).Config.AnalysisNote = obj.AcquisitionConfig.AnalysisNote.(device);
                    analysis_labels = string(fields(obj.(device).Config.AnalysisNote))';
                    obj.initAnalysisStorage(device, analysis_labels)
                end
            end
            obj.info("Storage initialized for %d devices, total memory is %g MB.", ...
                     length(obj.AcquisitionConfig.ActiveDevices), obj.MemoryUsage)
        end

        % Add new acquired image data to the storage
        function add(obj, new, options)
            arguments
                obj
                new = []
                options.verbose = false
            end
            timer = tic;
            if isempty(new)
                obj.warn("New data to add is empty.")
                return
            end
            obj.checkInitialized()
            obj.CurrentIndex = obj.CurrentIndex + 1;
            for camera = string(fields(new))'
                if obj.CurrentIndex > obj.MaxIndex
                    obj.(camera).Config.DataTimestamp = circshift(obj.(camera).Config.DataTimestamp, -1, 1);
                    obj.(camera).Config.DataTimestamp(end) = datetime;
                else
                    obj.(camera).Config.DataTimestamp(obj.CurrentIndex) = datetime;
                end
                for label = string(fields(new.(camera)))'
                    if obj.CurrentIndex > obj.MaxIndex
                        obj.shift(camera, label)
                    end
                    obj.addNew(new.(camera).(label), camera, label);
                end
            end
            if options.verbose
                obj.info('New data added to index %d in %.3f s', obj.CurrentIndex, toc(timer))
            end
        end
        
        % Configure the storage to a structure or another storage
        function config(obj, data, options)
            arguments
                obj
                data
                options.config_cameras = true
                options.config_acq = true
            end
            if options.config_acq
                obj.AcquisitionConfig.config(data.AcquisitionConfig)
            end
            if options.config_cameras
                obj.CameraManager.config(data)
            end
            obj.initMaxIndex()
            for camera = obj.ConfigurableProp
                if isfield(data, camera) || isprop(data, camera)
                    obj.(camera) = data.(camera);
                else
                    obj.(camera) = [];
                end
            end
            obj.CurrentIndex = obj.MaxIndex;
        end
    end

    methods (Access = protected, Abstract, Hidden)
        data = removeIncomplete(obj, data)
        initAnalysisStorage(obj, camera, labels)
        initAcquisitionStorage(obj, camera, labels)
        shift(obj, camera, label)
        addNew(obj, new_data, camera, label)
    end

    methods (Access = protected, Sealed, Hidden)
        function checkInitialized(obj)
            if isempty(obj.CurrentIndex)
                obj.error("Storage is not initialized.")
            end
        end
    end

    methods (Static)
        function [obj, acq_config, cameras] = struct2obj(class_name, data, acq_config, cameras, options)
            arguments
                class_name
                data
                acq_config = []
                cameras = []
                options.test_mode = true
            end
            if isempty(acq_config)
                acq_config = AcquisitionConfig.struct2obj(data.AcquisitionConfig);
            end
            if isempty(cameras)
                cameras = CameraManager.struct2obj(data, "test_mode", options.test_mode);
            end
            obj = feval(class_name, acq_config, cameras);
            obj.configData(data)
            obj.info("Object created from structure.")
        end
    end

end
