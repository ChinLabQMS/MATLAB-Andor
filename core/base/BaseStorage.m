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
    end
    
    % Handle to track acquisition settings
    properties (SetAccess = immutable)
        StorageType
        AcquisitionConfig
        CameraManager
    end

    properties (SetAccess = protected)
        CurrentIndex = 0
        MaxIndex
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
    
        % Override struct in BaseObject
        function s = struct(obj, options)
            arguments
                obj
                options.check_incomplete = true
                options.completed_only = true
            end
            if options.check_incomplete && (obj.CurrentIndex < obj.MaxIndex)
                if options.completed_only
                    obj.warn("Incomplete dataset, only %d / %d, Only completed data is saved.", ...
                        obj.CurrentIndex, obj.MaxIndex)
                else
                    obj.warn("Incomplete dataset, only %d / %d.", ...
                        obj.CurrentIndex, obj.MaxIndex)
                end
            end
            s.AcquisitionConfig = obj.AcquisitionConfig.struct();
            for camera = obj.ConfigurableProp
                if isempty(obj.(camera))
                    continue
                end
                s.(camera) = obj.(camera);
                % Remove the data that is not yet acquired.
                if options.completed_only && (obj.CurrentIndex < obj.MaxIndex)
                    for label = string(fields(s.(camera)))'
                        if label == "Config"
                            continue
                        end
                        s.(camera).(label) = obj.removeIncomplete(s.(camera).(label));
                    end
                end
            end
        end

        % Initialize the storage to the acquisition and camera config
        function init(obj)
            obj.CurrentIndex = 0;
            obj.initMaxIndex();
            for camera = obj.ConfigurableProp
                obj.(camera) = [];
            end
            sequence = obj.AcquisitionConfig.ActiveSequence;
            for camera = obj.AcquisitionConfig.ActiveCameras
                % Record camera config
                obj.(camera).Config = obj.CameraManager.(camera).Config.struct();
                % Record some additional information to the camera config
                obj.(camera).Config.CameraName = camera;
                obj.(camera).Config.NumAcquisitions = obj.AcquisitionConfig.NumAcquisitions;
                obj.(camera).Config.NumStatistics = obj.AcquisitionConfig.NumStatistics;
                camera_seq = sequence((sequence.Camera == camera), :);
                for j = 1:height(camera_seq)
                    label = camera_seq.Label(j);
                    note = camera_seq.Note(j);
                    type = string(camera_seq.Type(j));
                    if contains(type, "Analysis")
                        obj.(camera).Config.AnalysisNote.(label) = note;
                        obj.initAnalysisStorage(camera, label)
                    elseif contains(type, "Acquire")
                        obj.(camera).Config.AcquisitionNote.(label) = note;
                        obj.initAcquisitionStorage(camera, label)
                    end
                end
            end
            obj.info("Storage initialized for %d cameras, total memory is %g MB.", ...
                     length(obj.AcquisitionConfig.ActiveCameras), obj.MemoryUsage)
        end

        % Add new data to the storage
        function add(obj, new, options)
            arguments
                obj
                new
                options.verbose = false
            end
            timer = tic;
            if isempty(new)
                return
            end
            obj.CurrentIndex = obj.CurrentIndex + 1;
            for camera = string(fields(new))'
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
        
        function usage = get.MemoryUsage(obj)
            s = obj.struct("check_incomplete", false, "completed_only", false); %#ok<NASGU>
            usage = whos('s').bytes / 1024^2;
        end
    end

    methods (Access = protected, Abstract, Hidden)
        data = removeIncomplete(obj, data)
        initMaxIndex(obj)
        initAnalysisStorage(obj, camera, label)
        initAcquisitionStorage(obj, camera, label)
        shift(obj, camera, label)
        addNew(obj, new_data, camera, label)
    end

    methods (Static)
        function [obj, acq_config, cameras] = struct2obj(data, acq_config, cameras, options)
            arguments
                data (1, 1) struct
                acq_config = []
                cameras = []
                options.class_name
                options.test_mode (1, 1) logical = true
            end
            if isempty(acq_config)
                acq_config = AcquisitionConfig.struct2obj(data.AcquisitionConfig);
            else
                acq_config.configProp(data.AcquisitionConfig);
            end
            if isempty(cameras)
                cameras = CameraManager.struct2obj(data, "test_mode", options.test_mode);
            else
                for camera = cameras.prop()
                    cameras.(camera).config(data.(camera).Config);
                end
            end
            obj = feval(options.class_name, acq_config, cameras);
            obj.initMaxIndex()
            for camera = acq_config.ActiveCameras
                obj.(camera) = data.(camera);
            end
            obj.CurrentIndex = obj.MaxIndex;
        end
    end

end
