function showPol(Pol,varargin)
    NumPoint = 40;
    AnimStep = 4;

    t = linspace(0,2*pi,NumPoint)';
    NumBeam = size(Pol,1);
    P = cell(1,3);
    U = zeros(NumPoint,3,NumBeam);
    if nargin>1
        Dir = varargin{1};
    else
        Dir = zeros(NumBeam,3);
    end
    for i = 1:NumBeam
        U(:,:,i) = real(exp(1i*t)*Pol(i,:));
    end
    
    figure
    for i = 1:NumBeam
        subplot(1,NumBeam,i)
        xlim([-1,1])
        ylim([-1,1])
        zlim([-1,1])
        axis([-1,1,-1,1,-1,1])
        xticks([-1,-0.5,0,0.5,1])
        yticks([-1,-0.5,0,0.5,1])
        zticks([-1,-0.5,0,0.5,1])
        xlabel('x')
        ylabel('y')
        zlabel('z')
        daspect([1 1 1])
        view(3)
        hold on
        grid on
        q = quiver3(0,0,0,Dir(i,1),Dir(i,2),Dir(i,3), ...
            "LineWidth",2,"ShowArrowHead","on","AutoScale","off");
        q.MaxHeadSize = 1;
        plot3(U(:,1,i),U(:,2,i),U(:,3,i),'LineWidth',2)
        P{i} = plot3(U(1,1,i),U(1,2,i),U(1,3,i),'Marker','o','MarkerSize',10, ...
            'MarkerEdgeColor','r','MarkerFaceColor','r');
    end
    
    for i = 1:AnimStep:NumPoint
        pause(0.1)
        for j = 1:NumBeam
            subplot(1,NumBeam,j)
            P{j}.XData = U(i,1,j);
            P{j}.YData = U(i,2,j);
            P{j}.ZData = U(i,3,j);
        end
        drawnow
    end
    for i = 1:NumBeam
        subplot(1,NumBeam,i)
        hold off
    end
end