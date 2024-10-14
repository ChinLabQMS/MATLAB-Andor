function [temperature,status] = checkTemperature(serial_number, Handle)
    arguments
        serial_number = 19330
        Handle (1,1) struct = struct()
    end
    setCurrentAndor(serial_number,Handle,verbose=false)
    
    [ret, temperature] = GetTemperatureF();    
    switch ret
        case atmcd.DRV_TEMPERATURE_STABILIZED
            status = sprintf('Temperature has stabilized at set point.');
        case atmcd.DRV_TEMP_NOT_REACHED
            status = sprintf('Temperature has not reached set point.');
        case atmcd.DRV_TEMP_DRIFT
            status = sprintf('Temperature had stabilised but has since drifted.');
        case atmcd.DRV_TEMP_NOT_STABILIZED
            status = sprintf('Temperature reached but not stabilized.');
    end
    
    fprintf('Current temperature: %g\nStatus: %s\n',temperature,status)
end