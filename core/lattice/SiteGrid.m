classdef SiteGrid < BaseProcessor

    properties (SetAccess = {?BaseObject})
        SiteFormat = "Hex"
        HexRadius = 20
        HexStep = 1
        RectRadiusX = 10
        RectRadiusY = 10
    end

    properties (SetAccess = protected)
        Sites
        NumSites
    end

    methods
        function [idx, num_sites] = selectBox(obj, options)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.Sites = obj.prepareSite(obj.SiteFormat, ...
                "latr", obj.HexRadius, ...
                "latr_step", obj.HexStep, ...
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
                options.latr_step = 1
            end    
            switch format
                case 'Rect'
                    [Y, X] = meshgrid(options.laty_range, options.latx_range);
                    sites = [X(:), Y(:)];
                case 'Hex'
                    r = options.latr;
                    step = options.latr_step;
                    [Y, X] = meshgrid(-r:step:r, -r:step:r);
                    idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
                    sites = [X(idx), Y(idx)];
                otherwise
                    error("Not implemented")
            end
        end
    end

end
