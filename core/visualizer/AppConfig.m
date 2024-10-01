classdef AppConfig < BaseObject
   
    properties
        Analysis = ["Signal: Max", "Signal: Variance", "Background: Max"]
        BigAxes1Index = "Andor19330: Image"
        BigAxes2Index = "Andor19331: Image"
        SmallAxes1Index = "Andor19330: Image"
        SmallAxes2Index = "Andor19330: Image"
        SmallAxes3Index = "Andor19330: Image"

        ScreenOffset = [10, 35, -20, -70]
        SequenceTable = SequenceRegistry.Sequence4Basic
    end

end
