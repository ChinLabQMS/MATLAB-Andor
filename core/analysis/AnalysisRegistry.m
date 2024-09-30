classdef AnalysisRegistry

    properties (Constant)
        FitCenter = struct("OutputVars", ["XCenter", "YCenter", "XWidth", "YWidth"], ...
                       "OutputData", [], ...
                       "FuncName", "fitCenter")
        FitGauss = struct("OutputVars", ["GaussX", "GaussY", "GaussXWid", "GaussYWid"], ...
                          "OutputData", [], ...
                          "FuncName", "fitGauss")
        FitPSF = struct("OutputVars", [], ... 
                        "OutputData", []) % "PSFImage"
        CalibLat = struct("OutputVars", [], ... % ["LatX", "LatY"]
                          "OutputData", []) % ["LatK", "LatV"]
        CalibDMD = struct("OutputVars", [], ... % ["DmdXC", "DmdYC"]
                          "OutputData", []) % "DmdV"
    end

end
