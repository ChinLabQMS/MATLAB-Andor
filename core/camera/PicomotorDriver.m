classdef PicomotorDriver < BaseManager
    
    properties (Constant)
        DLL_Address = [pwd, '/dlls/picomotor/UsbDllWrap.dll']
    end

    properties (SetAccess = immutable)
        USBAddress
        NPUSBHandle
        Picomotor1
        Picomotor2
        Picomotor3
        Picomotor4
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
            % Get a handle on the USB class
            NPASMtype = NPasm.AssemblyHandle.GetType('Newport.USBComm.USB');
            % Launch the class USB, it constructs and allows to use functions in USB.h
            obj.NPUSBHandle = System.Activator.CreateInstance(NPASMtype);
            obj.Picomotor1 = Picomotor(1, obj.NPUSBHandle, obj.USBAddress);
            obj.Picomotor2 = Picomotor(2, obj.NPUSBHandle, obj.USBAddress);
            obj.Picomotor3 = Picomotor(3, obj.NPUSBHandle, obj.USBAddress);
            obj.Picomotor4 = Picomotor(4, obj.NPUSBHandle, obj.USBAddress);
        end

        function init(obj)
            if ~obj.Initialized
                obj.NPUSBHandle.OpenDevices();
                querydata = System.Text.StringBuilder(64);
                obj.NPUSBHandle.Query(obj.USBAddress, '*IDN?', querydata);
                dev_info = char(ToString(querydata));
                if isempty(dev_info)
                    obj.error('Unable to connect, please check if the connection is used by other applications!')
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
            if ~obj.Initialized
                obj.warn2('Driver is not initialized!')
                return
            end
            for i = 1: length(options.channels)
                obj.("Picomotor" + string(i)).setCurrentHome();
            end
        end

        function val = getTargetPosition(obj, options)
            arguments
                obj
                options.channels = [1, 2, 3, 4]
                options.verbose = true
            end
            if ~obj.Initialized
                if options.verbose
                    obj.warn2('Driver is not initialized!')
                end
                val = nan(size(options.channels));
                return
            end
            val = zeros(1, length(options.channels));
            for i = 1: length(options.channels)
                val(i) = obj.("Picomotor" + string(i)).TargetPosition;
            end
        end
        
        function setTargetPosition(obj, options)
            arguments
                obj
                options.channels = 1
                options.targets = 0
                options.scan_init = false
                options.scan = false
                options.scan_begin = -10
                options.scan_num_step = 10
                options.scan_step_size = 1
            end
            if ~obj.Initialized
                obj.warn2('Driver is not initialized!')
                return
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
                options.targets = curr_pos;
            end
            mustBeValidPosition(options.targets, options.channels)
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
