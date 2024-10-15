classdef ReplayerConfig < BaseObject

    properties (SetAccess = {?BaseRunner})
        DataPath (1, 1) string = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
    end

    properties (SetAccess = immutable)
        TestMode = AppConfig.TestMode
    end

end
