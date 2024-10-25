classdef BaseStorage < BaseObject
    %BASESTORAGE Base class for storage objects. 
    % This class is used to store data/analysis results, providing a common
    % interface for saving/loading data and exporting to other formats, as well
    % as for checking the current index and memory usage of the storage object.
    % Only the properties that are storing data should be visible to the user.
    
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
        function obj = BaseStorage(storage_type, config, cameras)
            obj.StorageType = storage_type;
            obj.AcquisitionConfig = config;
            obj.CameraManager = cameras;
        end

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
                        elseif class(s.(camera).(label)) == "table"
                            s.(camera).(label) = s.(camera).(label)(1:obj.CurrentIndex, :);
                        elseif isnumeric(s.(camera).(label))
                            s.(camera).(label) = s.(camera).(label)(:, :, 1:obj.CurrentIndex);
                        else
                            obj.error("Unrecongnized data types.")
                        end
                    end
                end
            end
        end

        % Initialize the storage
        function init(obj)
            obj.CurrentIndex = 0;
            switch obj.StorageType
                case "data"
                    obj.MaxIndex = obj.AcquisitionConfig.NumAcquisitions;
                case "stat"
                    obj.MaxIndex = obj.AcquisitionConfig.NumStatistics;
            end
            sequence = obj.AcquisitionConfig.ActiveSequence;
            for camera = obj.ConfigurableProp
                obj.(camera) = [];
            end
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
                        if obj.StorageType == "stat"
                            out_vars = obj.AcquisitionConfig.AnalysisOutVars.(camera).(label);
                            out_data = obj.AcquisitionConfig.AnalysisOutData.(camera).(label);
                            if length(out_vars) + length(out_data) > 0
                                obj.(camera).(label) = table( ...
                                    'Size', [obj.AcquisitionConfig.NumStatistics, length(out_vars) + length(out_data)], ...
                                    'VariableTypes', [repmat("doublenan", 1, length(out_vars)), ...
                                                      repmat("cell", 1, length(out_data))], ...
                                    'VariableNames', [out_vars, out_data]);
                            end
                        end
                    elseif contains(type, "Acquire")
                        obj.(camera).Config.AcquisitionNote.(label) = note;
                        if obj.StorageType == "data"
                            if obj.(camera).Config.MaxPixelValue <= 65535
                                obj.(camera).(label) = zeros(obj.(camera).Config.XPixels, ...
                                    obj.(camera).Config.YPixels, obj.AcquisitionConfig.NumAcquisitions, "uint16");
                            else
                                obj.error("Unsupported pixel value range for camera %s.", camera)
                            end
                        end
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
                    new_data = new.(camera).(label);
                    if obj.StorageType == "data"
                        if obj.CurrentIndex > obj.MaxIndex
                            obj.(camera).(label) = circshift(obj.(camera).(label), -1, 3);
                            obj.(camera).(label)(:, :, end) = new_data;
                        else
                            obj.(camera).(label)(:, :, obj.CurrentIndex) = new_data;
                        end
                    elseif obj.StorageType == "stat"
                        new_data = struct2table(new_data);
                        if obj.CurrentIndex > obj.MaxIndex
                            obj.(camera).(label) = circshift(obj.(camera).(label), -1, 1);
                            obj.(camera).(label)(end, :) = new_data;
                        else
                            obj.(camera).(label)(obj.CurrentIndex, :) = new_data;
                        end                        
                    end
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

end
