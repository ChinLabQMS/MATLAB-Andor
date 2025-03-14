function [Freq,FreqVec,FitData] = fitTrapFreq(Center,Func)

    % Fit radius in um
    RFit = 0.05;
    RMax = 1;
    Step = 0.01;

    mCs = 2.20694650e-25;

    XRange = Center(1)+(-RMax:Step:RMax);
    YRange = Center(2)+(-RMax:Step:RMax);
    ZRange = Center(3)+(-RMax:Step:RMax);
    
    % For a large region, find the trap center
    [Y,X,Z] = meshgrid(YRange,XRange,ZRange);
    PotentialAll = 2/mCs*Func([X(:),Y(:),Z(:)]);
    [~,Index] = max(PotentialAll);
    XCenter = X(Index);
    YCenter = Y(Index);
    ZCenter = Z(Index);
    if XCenter==XRange(1) || XCenter==XRange(end)
        warning('XCenter is at the edge')
    end
    if YCenter==YRange(1) || YCenter==YRange(end)
        warning('YCenter is at the edge')
    end
    if ZCenter==ZRange(1) || ZCenter==ZRange(end)
        warning('ZCenter is at the edge')
    end

    NewXRange = XCenter+(-RFit:Step:RFit);
    NewYRange = YCenter+(-RFit:Step:RFit);
    NewZRange = ZCenter+(-RFit:Step:RFit);
    
    % For a smaller region, fit the trap frequency
    [Y,X,Z] = meshgrid(NewYRange,NewXRange,NewZRange);
    Potential = 2/mCs*Func([X(:),Y(:),Z(:)]);
    Poly222 = @(b,x) b(1)+b(2)*x(:,1)+b(3)*x(:,2)+b(4)*x(:,3)+ ...
        b(5)*x(:,1).*x(:,2)+b(6)*x(:,1).*x(:,3)+b(7)*x(:,2).*x(:,3)+ ...
        b(8)*x(:,1).^2+b(9)*x(:,2).^2+b(10)*x(:,3).^2;
    StartPoint = [min(Potential),0,0,0,0,0,0,0,0,0];

    warning off all
    Model = fitnlm([X(:),Y(:),Z(:)],Potential,Poly222,StartPoint);
    warning on all
    
    Fit = Model.Coefficients{:,1};
    [V,D] = eig([Fit(8),Fit(5)/2,Fit(6)/2;Fit(5)/2,Fit(9),Fit(7)/2; ...
        Fit(6)/2,Fit(7)/2,Fit(10)],'vector');
    [D,I] = sort(D,'descend');
    V = V(:,I);
    Freq = sqrt(-D)*1e6/(2*pi);
    FreqVec = (V./vecnorm(V))';

    FitData = {[X(:),Y(:),Z(:)],Potential,Model};
end