function [BgOffset,STD,residuals] = cancelOffset(signal,num_frames,options)
    arguments
        signal
        num_frames (1,1) double = 1
        options.y_bg_size (1,1) double = 100
    end
   
    [XPixels,YPixels] = size(signal);
    XSize = XPixels/num_frames;

    BgOffset = zeros(XPixels,YPixels);
    STD = zeros(num_frames,2);

    if YPixels<2*options.y_bg_size+200
        error('Not enough space to cancel background offset!')
    end

    y_range1 = 1:options.y_bg_size;
    y_range2 = YPixels+(1-options.y_bg_size:0);
    residuals = cell(num_frames,2);
    for i = 1:num_frames
        x_range = (i-1)*XSize+(1:XSize);
        BgBox1 = signal(x_range,y_range1);
        BgBox2 = signal(x_range,y_range2);
        [XOut1,YOut1,ZOut1] = prepareSurfaceData(x_range,y_range1',BgBox1');
        [XOut2,YOut2,ZOut2] = prepareSurfaceData(x_range,y_range2',BgBox2');
        XOut = [XOut1;XOut2];
        YOut = [YOut1;YOut2];
        ZOut = [ZOut1;ZOut2];
        XYFit = fit([XOut,YOut],ZOut,'poly11');
        
        % Background offset canceling with fitted plane
        BgOffset(x_range,:) = XYFit.p00+XYFit.p10*x_range'+XYFit.p01*(1:YPixels);

        BgBoxNew1 = BgBox1-BgOffset(x_range,y_range1);
        BgBoxNew2 = BgBox2-BgOffset(x_range,y_range2);
        STD(i,:) = [std(BgBoxNew1(:)),std(BgBoxNew2(:))];
        
        residuals{i,1} = BgBoxNew1;
        residuals{i,2} = BgBoxNew2;
    end
    
    warning('off','backtrace')
    if any(abs(BgOffset)>2)
        warning('Noticable background offset after subtraction: %4.2f.Please check imaging conditions.\n',max(BgOffset(:)))
    end
    if any(STD>6)
        warning('Noticable background noise after cancellation: %4.2f',max(STD(:)))
    end
    warning('on','backtrace')
end