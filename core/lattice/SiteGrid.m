classdef SiteGrid < BaseProcessor

    properties (SetAccess = {?BaseObject})
        SiteFormat = "Hex"
        HexRadiusR = 20
        RectRadiusX = 10
        RectRadiusY = 10
    end

    properties (SetAccess = protected)
        Sites
        NumSites
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.Sites = obj.prepareSite(obj.SiteFormat, ...
                "latr", obj.HexRadiusR, ...
                "latx_range", -obj.RectRadiusX: obj.RectRadiusX, ...
                "laty_range", -obj.RectRadiusY: obj.RectRadiusY);
            obj.NumSites = size(obj.Sites, 1);
        end
    end

    methods (Static)
        function sites = prepareSite(format, options)
            arguments
                format (1, 1) string = "Hex"
                options.latx_range = -10:10
                options.laty_range = -10:10
                options.latr = 10
            end    
            switch format
                case 'Rect'
                    [Y, X] = meshgrid(options.laty_range, options.latx_range);
                    sites = [X(:), Y(:)];
                case 'Hex'
                    r = options.latr;
                    [Y, X] = meshgrid(-r:r, -r:r);
                    idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
                    sites = [X(idx), Y(idx)];
                otherwise
                    error("Not implemented")
            end
        end
    end

end
