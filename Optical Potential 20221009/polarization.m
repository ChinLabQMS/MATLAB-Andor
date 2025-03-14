% Lin per Lin config
Theta = 70/180*pi;
Beta = 8/180*pi;
Axis = [0,sin(Beta),cos(Beta)];

P1 = [1,0,0];
P2 = [cos(Theta),sin(Theta),0];

Z = -1:0.01:1;
E1 = exp(1i*2*pi*Z')*P1;
E2 = exp(-1i*2*pi*Z')*P2;
E = E1+E2;
I = vecnorm(E,2,2).^2;

Pol = E./vecnorm(E,2,2);
B = 1i*cross(conj(Pol),Pol).*I;

figure(Units="normalized",OuterPosition=[0.1,0.1,0.4,0.7])
sgtitle([sprintf('Lin Ang=%.2g',Theta/pi),'\pi Lin configuration'])
subplot(4,1,1)
plot(Z,I,LineWidth=1)
title('Intensity')
ylim([0,5])
xlabel('Z')
hold on
line([0,0],ylim,LineStyle='--',Color='k',LineWidth=1)

subplot(4,1,2)
plot(Z,B(:,1),LineWidth=1)
title('Bx')
xlabel('Z')
hold on
line([0,0],ylim,LineStyle='--',Color='k',LineWidth=1)

subplot(4,1,3)
plot(Z,B(:,2),LineWidth=1)
title('By')
xlabel('Z')
hold on
line([0,0],ylim,LineStyle='--',Color='k',LineWidth=1)

subplot(4,1,4)
plot(Z,B(:,3),LineWidth=1)
title('Bz')
xlabel('Z')
hold on
line([0,0],ylim,LineStyle='--',Color='k',LineWidth=1)