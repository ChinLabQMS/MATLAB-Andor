classdef DMDConfig < BaseConfig
    
    properties (Constant)
        MexFunctionName = "PatternWindowMex"
        DefaultStaticPatternPath = "resources/solid/white.bmp"
        PixelArrangement = "Diamond"
        PixelSize = 7.6
        PreloadPatternPath = ["resources/sequence/whiteband/GRB_1_whiteband.bmp", ...
                              "resources/sequence/whiteband/GRB_2_whiteband.bmp", ...
                              "resources/sequence/whiteband/GRB_3_whiteband.bmp", ...
                              "resources/sequence/whiteband/GRB_4_whiteband.bmp"]
    end

end
