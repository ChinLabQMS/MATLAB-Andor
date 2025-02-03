classdef DMD < Projector
    
    properties (SetAccess = immutable)
        MexFunctionName = "PatternWindowMex"
        DefaultStaticPatternPath = "resources/solid/white.bmp"
        PixelArrangement = "Diamond"
    end

end
