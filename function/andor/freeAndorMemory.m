function freeAndorMemory(serial, Handle)
    arguments
        serial
        Handle (1,1) struct = struct()
    end
    setCurrentAndor(serial,Handle,"verbose",false)
    
    % Free internal memory
    [ret] = FreeInternalMemory();
    CheckWarning(ret)
end