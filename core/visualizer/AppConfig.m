classdef AppConfig < BaseObject
   
    properties
        Analysis = ["Signal: Max", "Background: Max"]
        BigAxes1Index = "Andor19330: Image"
        BigAxes2Index = "Andor19331: Image"
        SmallAxes1Index = "Andor19330: Image"
        SmallAxes2Index = "Andor19330: Image"
        SmallAxes3Index = "Andor19330: Image"
        SmallAxes4Index = "Andor19331: Image"
        SmallAxes5Index = "Zelux: Lattice"

        ScreenOffset = [10, 35, -20, -70]
        SequenceTable = SequenceRegistry.Sequence4Analysis
    end
    
    properties (Dependent)
        TestMode
    end
        
    methods
        function mode = get.TestMode(~)
            name = getComputerName();
            switch name
                case "CCHIN-LABPC2"
                    mode = false;
                otherwise
                    mode = true;
            end
        end
    end

end

function name = getComputerName()
    % GETCOMPUTERNAME returns the name of the computer (hostname)
    % name = getComputerName()
    %
    % WARN: output string is converted to lower case
    %
    %
    % See also SYSTEM, GETENV, ISPC, ISUNIX
    %
    % m j m a r i n j (AT) y a h o o (DOT) e s
    % (c) MJMJ/2007
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
