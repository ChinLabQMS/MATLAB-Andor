classdef SiteCounter < BaseComputer

    properties (Constant)
        Count_DefaultMethod = "linear_inverse"
    end

    properties (SetAccess = immutable)
        SiteGrid
        PointSource
        Lattice
    end

    properties (SetAccess = protected)
        DeconvPattern
    end
    
    methods
        function obj = SiteCounter(id, lat, ps, grid)
            obj@BaseComputer(id)
            obj.Lattice = lat;
            obj.PointSource = ps;
            obj.SiteGrid = grid;
        end

        function stat = count(obj, signal, x_range, y_range, options)
            arguments
                obj
                signal
                x_range = 1: size(signal, 1)
                y_range = 1: size(signal, 2)
                options.count_method = obj.Count_DefaultMethod
            end
            stat = obj.SiteGrid.struct();
            switch options.count_method
                case "max_signal"

                case "linear_inverse"
            end
        end

        function updateDeconvPattern(obj)
        end
    end

    methods (Access = protected)
        function count = getCount_MaxSignal(obj, signal, x_range, y_range)
            
        end
        
        function count = getCount_LinearInverse(obj, signal, x_range, y_range)
        
        end
    end

end

function Count = getCount(Signal,XStart,Deconv)
    XPixels = size(Signal,1);
    NumSite = size(Deconv,1);
    NumSubImg = size(XStart,1);
    Count = zeros(NumSite,NumSubImg);

    for i = 1:NumSite
        List = Deconv{i,1}+XPixels*(Deconv{i,2}-1);
        if size(List,1)>0
            for j = 1:NumSubImg
                Count(i,j) = Deconv{i,3}'*Signal(List+XStart(j)-1); %only
                %line in original code
%                 Count(i,j) = ones(size(Deconv{i,3}'))*Signal(List+XStart(j)-1);
            end
        end
    end
end

function  [Deconv,DecPat] = getDeconv(Lat,funcPSF,Site,XLim,YLim)
    
    % Default deconvolution parameters
    PSFR = 10;
    RPattern = 30;
    Factor = 5;
    LatRLim = 2;
    RDeconv = 15;
    Threshold = 0.01;
    
    % Initialize
    NumSite = size(Site,1);
    Deconv = cell(NumSite,3);
    
    % Get the deconvolution pattern
    DecPat = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim);
    %DecPat = ones(size(DecPat));
    %DecPat = DecPat/sum(DecPat,"all");
    
    % For each lattice site, find corresponding pixels and weights
    for i = 1:NumSite

        % Convert lattice X-Y index to CCD space coordinates
        Center = Site(i,:)*Lat.V+Lat.R;
        
        % Find X and Y range of pixels
        CX = round(Center(1));
        CY = round(Center(2));

        XMin = max(CX-RDeconv,1);
        XMax = min(CX+RDeconv,XLim);
        YMin = max(CY-RDeconv,1);
        YMax = min(CY+RDeconv,YLim);
        
        % Generate a list of pixel coordinates
        [Y,X] = meshgrid(YMin:YMax,XMin:XMax);
        XList = X(:);
        YList = Y(:);
        
        % Find the distance to site center
        XDis = XList-Center(1);
        YDis = YList-Center(2);
       
        % Find the cooresponding index in the deconvolution pattern
        XDeconv = round(Factor*(XDis+RPattern))+1;
        YDeconv = round(Factor*(YDis+RPattern))+1;
        XYDeconv = XDeconv+(YDeconv-1)*(2*Factor*RPattern+1);
        
        % Assign weights
        WeightList = DecPat(XYDeconv);
        Index = abs(WeightList)>Threshold;     
        Deconv{i,1} = XList(Index);
        Deconv{i,2} = YList(Index);
        Deconv{i,3} = WeightList(Index);
    end
    
end

function Pattern = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim)
% Calculate deconvolution pattern by inverting (-LatRLim:LatRLim) PSF

    % Number of sites
    NumSite = (2*LatRLim+1)^2;

    % Number of pixels
    NumPx = (2*Factor*RPattern+1)^2;

    M = zeros(NumSite,NumPx);
    if funcPSF(PSFR,PSFR)>0.001
        warning(['Probability density at edge is significant = %.4f\nCheck' ...
            ' PSFR (radius for calculating PSF spread)'],funcPSF(PSFR,PSFR))
    end
    
    % For each lattice site, find its spread into nearby pixels
    for i = -LatRLim:LatRLim
        for j = -LatRLim:LatRLim
            
            % Site index
            Site = (i+LatRLim+1)+(j+LatRLim)*(2*LatRLim+1);

            % Lattice site coordinate
            Center = [i,j]*Lat.V;

            % Convert coordinate to magnified pixel index
            CXIndex = round(Factor*(Center(1)+RPattern))+1;
            CYIndex = round(Factor*(Center(2)+RPattern))+1;

            % Range of pixel index to run through
            xMin = CXIndex-PSFR*Factor;
            xMax = CXIndex+PSFR*Factor;
            yMin = CYIndex-PSFR*Factor;
            yMax = CYIndex+PSFR*Factor;

            % Go through all pixels and assign the spread
            x = xMin:xMax;
            y = yMin:yMax;
            Pixel = x'+(y-1)*(2*Factor*RPattern+1);
            [YP,XP] = meshgrid((y-1)/Factor-RPattern,(x-1)/Factor-RPattern);
            M(Site,Pixel) = funcPSF(XP(:)-Center(1),YP(:)-Center(2))/Factor^2;
            
        end
    end

    % Convert transfer matrix to deconvolution pattern
    MInv = (M*M')\M;
    Pattern = reshape(MInv(round(NumSite/2),:),sqrt(NumPx),[]);

    % Re-normalize deconvolution pattern
    Area = abs(det(Lat.V));
    %disp(Area);
    Pattern = Area/(sum(Pattern,"all")/Factor^2)*Pattern;
    %Pattern= Pattern/sum(Pattern,"all");
end

