function setCurrentAndor(serial, Handle, options)
    arguments
        serial = 19330
        Handle (1, 1) struct = struct()
        options.verbose = true
    end

    if isstring(serial) || ischar(serial)
        serial_str = serial;
        serial = str2double(serial(6:end));
    else
        serial_str = ['Andor', num2str(serial)];
    end

    Handle = getAndorHandle(serial_str, Handle, "verbose",options.verbose);
    [ret] = SetCurrentCamera(Handle.(serial_str));
    CheckWarning(ret)
    
    if options.verbose
        fprintf('Camera (serial: %d, handle: %d) is set to current CCD\n',...
                serial, Handle.(serial_str))
    end   
end