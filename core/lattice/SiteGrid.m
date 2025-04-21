classdef SiteGrid < BaseProcessor

    properties (SetAccess = {?BaseObject})
        SiteFormat = "Hex"
        HexRadius = 20
        HexStep = 1
        RectRadiusX = 10
        RectRadiusY = 10
        MaskXLim = [0, 100]
        MaskYLim = [0, 1024]
        % BinGroupType = "none"
        % BinGroupIndex = []
    end

    properties (SetAccess = protected)
        Sites
        NumSites
    end

    properties (SetAccess = immutable)
        Lattice
    end

    methods
        function obj = SiteGrid(lat)
            arguments
                lat = []
            end
            obj.Lattice = lat;
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.Sites = obj.prepareSite( ...
                obj.SiteFormat, ...
                "latr", obj.HexRadius, ...
                "latr_step", obj.HexStep, ...
                "latx_range", -obj.RectRadiusX: obj.RectRadiusX, ...
                "laty_range", -obj.RectRadiusY: obj.RectRadiusY, ...
                "mask_xlim", obj.MaskXLim, ...
                "mask_ylim", obj.MaskYLim, ...
                "mask_Lattice", obj.Lattice);
            obj.NumSites = size(obj.Sites, 1);
        end
    end

    methods (Static)
        function sites = prepareSite(format, options)
            arguments
                format (1, 1) string = "Hex"
                options.latr = 10
                options.latr_step = 1
                options.latx_range = -10:10
                options.laty_range = -10:10
                options.mask_Lattice = []
                options.mask_xlim = [0, 100]
                options.mask_ylim = [0, 1024]
            end    
            switch format
                case {"Rect", "MaskedRect"}
                    [Y, X] = meshgrid(options.laty_range, options.latx_range);
                    sites = [X(:), Y(:)];
                case {"Hex", "MaskedHex"}
                    r = options.latr;
                    step = options.latr_step;
                    [Y, X] = meshgrid(-r:step:r, -r:step:r);
                    idx = (Y(:) <= X(:) + r) & (Y(:) >= X(:) - r);
                    sites = [X(idx), Y(idx)];
                otherwise
                    error("Not implemented")
            end
            switch format
                case {"MaskedRect", "MaskedHex"}
                    if isempty(options.mask_Lattice)
                        error('Can not create masked sites without providing a valid lattice calibration')
                    else
                        [~, sites] = options.mask_Lattice.convert2Real(sites, ...
                            "filter", true, "x_lim", options.mask_xlim, "y_lim", options.mask_ylim);
                    end
                otherwise
            end
        end
    end
end
