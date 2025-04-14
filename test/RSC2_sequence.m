f=1e6;
T=1/f;
x=linspace(0,3*T,100);

shift = 2;

y0 = ones(size(x));
y1 = ones(size(x))+shift;
y2 = heaviside(sin(2*pi*f*x))+2*shift;
y3 = heaviside(-sin(2*pi*f*x))+3*shift;

hold on
plot(x,y0,'LineWidth',2, 'Color', 	"#7E2F8E")
plot(x,y1,'LineWidth',2, 'Color', 	"#0072BD")
plot(x,y2,'LineWidth',2, 'Color', 	"#D95319")
plot(x,y3,'LineWidth',2, 'Color', 	"#77AC30")

yline(0,'--k');yline(shift,'--k');yline(2*shift,'--k');yline(3*shift,'--k');
ylim([-0.5 4*shift])
yticks([0, shift,2*shift,3*shift]+shift/2);
yticklabels({'RSC Repump','935 nm Lat','RSC OP','1064 nm LS'});
ytickangle(30)
xlabel('Time (s)')
fontsize(gca,scale=1.5)

box on