classdef Picomotor < BaseProcessor

    properties (Constant)
        Max_Position = 500
        Min_Position = -500
    end
    
    properties (SetAccess = immutable)
        Channel
        DriverHandle
    end

    properties (SetAccess = {?BaseObject})
        ScanStart
        ScanNumStep
        ScanStepSize
    end

    properties (SetAccess = protected)
        TargetPosition
        ScanPosition
    end

    properties (Dependent)
        ScanStop
    end
    
    methods
        function obj = Picomotor(channel, handle)
            arguments
                channel = 1
                handle = PicomotorDriver()
            end
            obj@BaseProcessor('init', false, 'reset_fields', false)
            obj.Channel = channel;
            obj.DriverHandle = handle;
        end

        function setTargetPosition(obj, pos, options)
            arguments
                obj
                pos
                options.verbose = true
            end
            if isempty(pos)
                return
            end
            obj.assert((pos >= obj.Min_Position) && (pos <= obj.Max_Position), ...
                'Position out of range! Max: %d, Min: %d, Pos: %d', ...
                obj.Max_Position, obj.Min_Position, pos)
            if obj.DriverHandle.Initialized
                if ~isempty(obj.DriverHandle.NPUSBHandle)
                    obj.DriverHandle.NPUSBHandle.Write(obj.USBAddress, sprintf('%d PA %d', obj.Channel, pos));
                end
                obj.TargetPosition = pos;
                if options.verbose
                    obj.info('Picomotor set to new position: %d.', pos)
                end
            else
                obj.warn2('Driver is not initialized, unable to set target position!')
            end
        end

        function val = get.TargetPosition(obj)
            if obj.DriverHandle.Initialized
                if ~isempty(obj.DriverHandle.NPUSBHandle)
                    querydata = System.Text.StringBuilder(64);
                    obj.DriverHandle.NPUSBHandle.Query(obj.USBAddress, sprintf('%d PA?', obj.Channel), querydata);
                    obj.TargetPosition = double(string(ToString(querydata)));
                end
                val = obj.TargetPosition;
            else
                val = [];
                obj.warn2('Driver is not initialized, unable to get target position!')
            end
        end

        function setCurrentHome(obj)
            if obj.DriverHandle.Initialized
                if ~isempty(obj.DriverHandle.NPUSBHandle)
                    obj.DriverHandle.Write(obj.USBAddress, sprintf('%d DH', obj.Channel));
                end
                obj.TargetPosition = 0;
            else
                obj.warn2('Driver is not initialized, unable to set current position home!')
            end
        end

        function scan(obj, varargin)
            if isempty(obj.ScanPosition)
                obj.error('Scan is not configured!')
            end
            obj.setTargetPosition(obj.ScanPosition, varargin{:})
            if obj.ScanPosition - obj.ScanStart <= (obj.ScanNumStep - 1) * obj.ScanStepSize
                obj.ScanPosition = obj.ScanPosition + obj.ScanStepSize;
            else
                obj.ScanPosition = obj.ScanStart;
            end
        end

        function val = get.ScanStop(obj)
            if (~isempty(obj.ScanStart)) && (~isempty(obj.ScanNumStep)) && (~isempty(obj.ScanStepSize))
                val = obj.ScanStart + obj.ScanNumStep * obj.ScanStepSize;
            else
                val = [];
            end
        end
    end

    methods (Access = protected)
        % Initialize scan if all scan parameters are configured
        function init(obj)
            if (~isempty(obj.ScanStart)) && (~isempty(obj.ScanNumStep)) && (~isempty(obj.ScanStepSize))
                obj.ScanPosition = obj.ScanStart;
            else
                obj.ScanPosition = [];
            end
        end
    end
    
    methods (Access = protected, Hidden)
        function label = getStatusLabel(obj)
            label = string(class(obj)) + string(obj.Channel);
        end
    end

end
