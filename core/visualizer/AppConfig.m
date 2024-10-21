classdef AppConfig < BaseObject

    properties (Constant)
        BaseAnalysis = ["Signal: Max", "Background: Max", "Background: Variance"]
        SequenceName = "Full4Analysis"
        TestMode = getTestMode()
        FigurePosition = getFigurePosition()
        Acquisition_DropBadFrame = true
        Acquisition_VerboseStart = false
        Acquisition_VerboseAcquire = true
        Acquisition_VerbosePreprocess = false
        Acquisition_VerboseAnalysis = false
        Acquisition_VerboseLayout = true
        Acquisition_VerboseStorage = false
        Acquisition_Verbose = true
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

function mode = getTestMode()
    name = getComputerName();
    switch name
        case "CCHIN-LABPC2"
            mode = false;
        otherwise
            mode = true;
    end
end

function position = getFigurePosition()
    % Get screen size to set the APP dimension
    s = get(0, "MonitorPositions");
    position = s(1, :) + [10, 35, -20, -70];
    for i = 2:size(s, 1)
        if isequal(s(i,3:4), [1920,1080])
            position = s(i, :) + [10, 35, -20, -70];
            return
        end
        if isequal(s(i,3:4), [2048,1152])
            position = [2051 263 860 976];
            return
        end
    end
end
