classdef PicomotorDriver < BaseManager
    
    properties (Constant)
        DLL_Address = fullfile(pwd, '/dlls/picomotor/UsbDllWrap.dll')
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
        Initialized
    end

    methods
        function obj = PicomotorDriver(test_mode, usb_address)
            arguments
                test_mode = true
                usb_address = 1
            end
            obj.USBAddress = usb_address;
            if test_mode
                obj.NPUSBHandle = [];
            else
                NPasm = NET.addAssembly(obj.DLL_Address);
                % Get a handle on the USB class
                NPASMtype = NPasm.AssemblyHandle.GetType('Newport.USBComm.USB');
                % Launch the class USB, it constructs and allows to use functions in USB.h
                obj.NPUSBHandle = System.Activator.CreateInstance(NPASMtype);
            end
            obj.Picomotor1 = Picomotor(1, obj);
            obj.Picomotor2 = Picomotor(2, obj);
            obj.Picomotor3 = Picomotor(3, obj);
            obj.Picomotor4 = Picomotor(4, obj);
            obj.Initialized = false;
        end
        
        % Initialize driver connection via USB interface
        function init(obj)
            if ~obj.Initialized
                if ~isempty(obj.NPUSBHandle)
                    obj.NPUSBHandle.OpenDevices();
                    querydata = System.Text.StringBuilder(64);
                    obj.NPUSBHandle.Query(obj.USBAddress, '*IDN?', querydata);
                    dev_info = char(ToString(querydata));
                    if isempty(dev_info)
                        obj.error('Unable to connect, please check if the connection is used by other applications!')
                    else
                        % display device ID to make sure it's recognized OK
                        obj.info('Device attached is %s', dev_info);
                    end
                else
                    obj.info('Device connected.')
                end
                obj.Initialized = true;
            end
        end
        
        % Release the USB connection
        function close(obj)
            if obj.Initialized
                if ~isempty(obj.NPUSBHandle)
                    obj.NPUSBHandle.CloseDevices();
                end
                obj.Initialized = false;
                obj.info('Device disconnected.')
            end
        end
        
        % Main function to interface with sequence table in app
        function move(obj, options)
            arguments
                obj
                options.channel = 1
                options.target = 0
                options.scan = false
                options.scan_start = 0
                options.scan_num_step = 10
                options.scan_step_size = 1
            end
            label = "Picomotor" + string(options.channel);
            picomotor = obj.(label);
            if options.scan
                % If scan is not configured or different from before
                % initialize the scan
                if isempty(picomotor.ScanPosition) || ...
                        ~((picomotor.ScanStart == options.scan_start) && ...
                          (picomotor.ScanNumStep == options.scan_num_step) && ...
                          (picomotor.ScanStepSize == options.scan_step_size))
                    picomotor.config('ScanStart', options.scan_start, ...
                                     'ScanNumStep', options.scan_num_step, ...
                                     'ScanStepSize', options.scan_step_size)
                end
                % Move the piezo and update the scan position
                picomotor.scan()
            else
                % If it is previously configured as scan mode, clear it
                if ~isempty(picomotor.ScanPosition)
                    picomotor.config('ScanStart', [], 'ScanNumStep', [], 'ScanStepSize', [])
                end
                picomotor.setTargetPosition(options.target)
            end
        end
        
        function delete(obj)
            obj.close()
        end
    end
end
