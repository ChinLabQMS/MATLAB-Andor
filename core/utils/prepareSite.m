function [site, num_sites] = prepareSite(format, options)
    arguments
        format (1, 1) string = "parallel"
        options.x_range
        options.y_range
    end
    
    switch format
        case 'parallel'
            [Y, X] = meshgrid(LatFormat{3},LatFormat{2});
            site = [X(:), Y(:)];
        case 'hex'
            r=LatFormat{2};
            siteSum=1;
            for i=1:r
                siteSum = siteSum+6*i;
            end            
            x=-r:r;
            [a, b]=meshgrid(x,x);
            site=[a(:),b(:)];
            
            % Generating hexagon coordinates in lattice space
            for i=0:(r-1)
                for j=1:(r-i)
                    % disp([r-i, -(r-j+1)])
                    % disp([-(r-i), r-j+1])
                    if ismember([r-i, -(r-j+1)],site,"rows")==true || ismember([-(r-i), r-j+1],site,"rows")==true
                        [a,b]=ismember([r-i, -(r-j+1)],site,"rows");
                        site(b,:)=[];
                        [c,d]=ismember([-(r-i), r-j+1],site,"rows");
                        site(d,:)=[];
                        
                    end
                end
            end
            num_sites=numel(site)/2;
            % adjust this code so that we can first create inner 7, then
            % create the next 12, then the next 18, then the next 24, then
            % the next 30, to put them in order in Site so that it's easy
            % to separate them into the layers.        
    end
    num_sites = size(site, 1);
end
