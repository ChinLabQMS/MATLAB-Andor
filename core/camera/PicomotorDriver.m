classdef PicomotorDriver < BaseObject
    
    properties (Constant)
        DLL_Address = [pwd, '/dlls/picomotor/UsbDllWrap.dll']
        Range_Min = -500
        Range_Max = 500
    end

    properties (SetAccess = immutable)
        USBAddress
        NPUSBHandle
    end

    properties (SetAccess = protected)
        Initialized = false
    end

    methods
        function obj = PicomotorDriver(usb_address)
            arguments
                usb_address = 1
            end
            obj.USBAddress = usb_address;
            NPasm = NET.addAssembly(obj.DLL_Address);
            NPASMtype = NPasm.AssemblyHandle.GetType('Newport.USBComm.USB'); %Get a handle on the USB class
            obj.NPUSBHandle = System.Activator.CreateInstance(NPASMtype); %launch the class USB, it constructs and allows to use functions in USB.h
        end

        function init(obj)
            clear setTargetPosition
            if ~obj.Initialized
                obj.NPUSBHandle.OpenDevices();
                querydata = System.Text.StringBuilder(64);
                obj.NPUSBHandle.Query(obj.USBAddress, '*IDN?', querydata);
                dev_info = char(ToString(querydata));
                if isempty(dev_info)
                    obj.error('Unable to connect, please check if the connection is released by other applications!')
                else
                    obj.info('Device attached is %s', dev_info); %display device ID to make sure it's recognized OK
                end
                obj.Initialized = true;
            end
        end

        function close(obj)
            if obj.Initialized
                obj.NPUSBHandle.CloseDevices();
                obj.Initialized = false;
                obj.info('Device disconnected.')
            end
        end

        function setCurrentHome(obj, options)
            arguments
                obj
                options.channels = [1, 2, 3, 4]
            end
            for i = 1: length(options.channels)
                c = options.channels(i);
                obj.NPUSBHandle.Write(obj.USBAddress, sprintf('%d DH', c, t));
            end
        end

        function val = getTargetPosition(obj, options)
            arguments
                obj
                options.channels = [1, 2, 3, 4]
            end
            val = zeros(1, length(options.channels));
            for i = 1: length(options.channels)
                c = options.channels(i);
                querydata = System.Text.StringBuilder(64);
                obj.NPUSBHandle.Query(obj.USBAddress, sprintf('%d PA?', c), querydata);
                val(i) = double(char(ToString(querydata)));
            end
        end

        function setTargetPosition(obj, options)
            arguments
                obj
                options.channels = 1
                options.target = 0
                options.scan_init = false
                options.scan = false
                options.scan_begin = -10
                options.scan_num_step = 10
                options.scan_step_size = 1
            end
            persistent curr_pos
            persistent num_step
            if options.scan
                if isempty(curr_pos) || options.scan_init
                    curr_pos = options.scan_begin;
                    num_step = 1;
                elseif num_step + 1 <= options.scan_num_step
                    curr_pos = curr_pos + options.scan_step_size;
                    num_step = num_step + 1;
                else
                    curr_pos = options.scan_begin;
                    num_step = 1;
                end
                options.target = curr_pos;
            end
            mustBeValidPosition(options.target, options.channels)
            for i = 1: length(options.channels)
                c = options.channels(i);
                t = options.targets(i);
                obj.NPUSBHandle.Write(obj.USBAddress, sprintf('%d PA %d', c, t));
            end
        end

        function delete(obj)
            obj.close()
        end
    end
end

function mustBeValidPosition(position, channels)
    if length(position) ~= length(channels)
        error('Position input must have the same length and the channel inputs.')
    end
    mustBeGreaterThanOrEqual(position, PicomotorDriver.Range_Min)
    mustBeLessThanOrEqual(position, PicomotorDriver.Range_Max)
end
