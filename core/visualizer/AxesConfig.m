classdef AxesConfig
    %AXESCONFIG

    properties (SetAccess = {?AxesManager})
        Style (1, 1) string
        ImageIndex (1, 1) double
        Content (1, 1) string
        PlotHandle
    end

end