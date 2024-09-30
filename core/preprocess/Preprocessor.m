classdef Preprocessor < BaseRunner

    properties (SetAccess = protected)
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseRunner(config);
        end

        function init(obj)
            obj.Background = load(obj.Config.BackgroundFileLocation);
            fprintf("%s: Background loaded.\n", obj.CurrentLabel)
        end

        function [signal, leakage] = process(obj, raw, label, config, options)
            arguments
                obj
                raw (:, :, :) {mustBeNumeric}
                label (1, 1) string
                config (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            signal = obj.runBackgroundSubtraction(double(raw), label, config);
            [signal, leakage] = obj.runOffsetCorrection(signal, label,config);
            if options.verbose
                fprintf("%s: [%s %s] Preprocessing completed in %.3f s.\n", obj.CurrentLabel, config.CameraName, label, toc(timer))
            end
        end

        function [signal, leakage] = processSingleData(obj, data, varargin)
            signal = data;
            leakage = data;
            % -----Legacy support---------
            if isfield(data.Config, "AcquisitionNote")
                labels = string(fields(data.Config.AcquisitionNote)');
            elseif isfield(data.Config, "Note")
                labels = string(fields(data.Config.Note)');
            end
            for label = labels
                [signal.(label), leakage.(label)] = obj.process( ...
                    data.(label), label, data.Config, varargin{:});
            end
        end

        function [signal, leakage] = processData(obj, data, varargin)
            if isfield(data, "Config")
                [signal, leakage] = processSingleData(obj, data, varargin{:});
                return
            end
            signal = data;
            leakage = data;
            for field = string(fields(data)')
                % --------Legacy support-----------
                if field.endsWith("Config") || field.endsWith("SequenceTable")
                    continue
                end
                [signal.(field), leakage.(field)] = obj.processSingleData(data.(field), varargin{:});
            end
        end
    end

    methods (Access = protected)
        function signal = runBackgroundSubtraction(obj, raw, ~, config)
            if ~isfield(config, "Cropped")
                signal = raw;
                return
            end
            if config.Cropped
                str1 = "Cropped_";
            else
                str1 = "Full_";
            end
            %-------Legacy support--------
            if isfield(config, "ReadoutSpeed")
                str2 = config.ReadoutSpeed;
            else
                switch config.HSSpeed
                    case 0
                        str2 = "5MHz";
                    case 1
                        str2 = "3MHz";
                    case 2
                        str2 = "1MHz";
                end
            end
            try
                signal = raw - obj.Background.(str1 + str2).(config.CameraName).(obj.Config.BackgroundSubtractionParams.var_name);
            catch
                signal = raw;
            end
        end

        function signal = runOutlierRemoval(obj, raw, label, config)            
        end

        function [signal, leakage] = runOffsetCorrection(obj, raw, label, config)            
            switch obj.Config.OffsetCorrectionParams.method
                case "linear_plane"
                    if ~isfield(config, "FastKinetic") 
                        signal = raw;
                        leakage = zeros(size(raw, [1, 2]));
                        return
                    end
                    if config.FastKinetic
                        num_frames = config.FastKineticSeriesLength;
                    else
                        num_frames = 1;
                    end
                    leakage = cancelOffsetLinearPlane(raw, num_frames, ...
                        "region_width", obj.Config.OffsetCorrectionParams.region_width, ...
                        "warning", obj.Config.OffsetCorrectionParams.warning, ...
                        "warning_thres_offset", obj.Config.OffsetCorrectionParams.warning_thres_offset, ...
                        "warning_thres_var", obj.Config.OffsetCorrectionParams.warning_thres_var, ...
                        "warning_note", sprintf("%s: [%s %s] ", obj.CurrentLabel, config.CameraName, label));
                    signal = raw - leakage;
                otherwise
                    error("%s: %s method not implemented", obj.CurrentLabel, obj.Config.method)
            end
        end
    end

end
