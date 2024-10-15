classdef AppConfig < BaseObject

    properties (Constant)
        BaseAnalysis = ["Signal: Max", "Background: Max", "Background: Variance"]
        ScreenOffset = [10, 35, -20, -70]
        SequenceTable = "Full4Analysis"
        TestMode = getTestMode()
    end

end

function mode = getTestMode()
    name = getComputerName();
    switch name
        case "CCHIN-LABPC2"
            mode = false;
        otherwise
            mode = true;
    end
end

function name = getComputerName()
    % GETCOMPUTERNAME returns the name of the computer (hostname)
    % name = getComputerName()
    % See also SYSTEM, GETENV, ISPC, ISUNIX
    % MOD: MJMJ/2013
    [ret, name] = system('hostname');
    if ret ~= 0
       if ispc
          name = getenv('COMPUTERNAME');
       else      
          name = getenv('HOSTNAME');      
       end
    end
    name = string(strtrim(name));
end
