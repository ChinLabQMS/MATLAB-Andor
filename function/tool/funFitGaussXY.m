
% Fits atom-resolved cloud image to a 2D Gaussian
% Outputs center and width of fit

function [xc, wx, yc, wy,xlimits,ylimits] = funFitGaussXY(Data, numFK, varargin)
    fkShift=floor(1024/numFK); % use this line to fit the earlier image
    disp(numFK);
    % Data is already background-subtracted
    d=Data((1024-fkShift+1):1024,1:1024,:); % Fit first image- actually last image!!!
    %d=Data(1:fkShift,1:1024,:); % Fit last image

    [szY, szX] = size(d);

    xvec = linspace(1,szX,szX); % x coords if one is not provided
    yvec = linspace(1,szY,szY); % y coords if one is not provided
    
    xsum = sum(d,1); % integrated X profile (summed over rows)
    ysum = sum(d,2)'; % integrated Y profile (summed over cols)
    
    [xfit,xgof]=fitGaussX(xvec, xsum);
    [yfit,ygof]=fitGaussX(yvec, ysum);

    wx=xfit.w; % horizontal 1/e^2 radius
    wy=yfit.w; % vertical 1/e^2 radius
    xc=xfit.xc; % x0,y0 ellipse centre coordinates
    yc=yfit.xc;
    sx=xfit.w/2; % horizontal 1sigma
    sy=yfit.w/2; % horizontal 1sigma
    t=-pi:0.01:pi;
    xw=xc+wx*cos(t);
    yw=yc+wy*sin(t);
    xs=xc+sx*cos(t);
    ys=yc+sy*sin(t);

    % Plotting to check fit
    % figure
    % imagesc(Data)
    % colorbar
    % axis on
    % hold on
    % plot(xw, ys, 'r.', 'MarkerSize',10,'LineWidth',1)
    % hold off

hold off
    function [gXYfit, gXYgof] = fitGaussX(xvec, xsum)
    gaussXYEqn = 'a0*exp(-2*((x-xc)^2/w^2))+c'; % This fitted width is the 1/e^2 waist, NOT 1sigma.
    
    foLow = [0.001*min(xsum),xvec(1),0.01*(xvec(end)-xvec(1)),min(xsum)];
    % foLow = [min(xsum),xvec(1),0.01*(xvec(end)-xvec(1)),min(xsum)];
    foUp = [max(xsum),10*xvec(end),10*(xvec(end)-xvec(1)),max(xsum)];
    foStart = [mean(xsum),xvec(floor(length(xvec)/2)),0.25*(xvec(end)-xvec(1)),min(xsum)];

    disp(foLow)
    
    fo = fitoptions('Method','NonlinearLeastSquares',...
        'Lower',foLow,...
        'Upper',foUp,...
        'StartPoint',foStart);
    
    ft = fittype(gaussXYEqn,...
        'independent',{'x'},...
        'dependent',{'y'},...
        'coefficients',{'a0','xc','w','c'},...
        'options',fo);
    
    [gXYfit, gXYgof] = fit(xvec', xsum',ft);
    end

    xlimits=[xc-3*sy xc+3*sy];
    ylimits=[yc-3*sx yc+3*sx];


%     if nargin > 3
%         ax1=varargin{1};
% %         ax2=varargin{2};
% %         ax3=varargin{3};
%         imagesc(ax1,d); daspect([1 1 1]); colorbar
%         hold on
%         plot(ax1,xw,yw,'-k')
%         plot(ax1,xs,ys,'-r');
%         xline(ax1,xfit.xc,'--g')
%         yline(ax1,yfit.xc,'--g')
%         xlim(xlimits);
%         ylim(ylimits);
%         title({['XCenter: ',num2str(xc),', XWidth: ',num2str(wx)],['YCenter: ',num2str(yc),', YWidth: ',num2str(wy)]});
%         hold off
    % end
end