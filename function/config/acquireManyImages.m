function acquireManyImages(X,Y,Options)
    arguments
        X (1,1) double = 64
        Y (1,1) double = 512
        Options.ShowCross = false
    end
    Fig = figure(Name="Signal",Units="normalized",OuterPosition=[0,0,1,1]);
    while isvalid(Fig)
%         disp('Start acquiring ')
        Image = acquireCCDImage(TimeOutSecond=10);
%         Image = zeros(100,100);
%         disp('Image acquired')
        
        figure(Fig)
        imagesc(Image)
        daspect([1 1 1])
        colorbar

        if Options.ShowCross
            hold on
            line([1,1024],[X,X],Color='k',LineStyle='--')
            line([Y,Y],[1,1024],Color='k',LineStyle='--')
            hold off
        end
        pause(0.2)
    end
    disp('Video stopped')
end