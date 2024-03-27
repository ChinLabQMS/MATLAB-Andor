function [offset,variance,residuals] = cancelOffset(signal,num_frames,options)
    arguments
        signal
        num_frames (1,1) double = 1
        options.y_bg_size (1,1) double = 100
        options.noise_var (1,1) double = 31;
    end
   
    [XPixels,YPixels] = size(signal);
    XSize = XPixels/num_frames;

    offset = zeros(XPixels,YPixels);
    variance = zeros(num_frames,2);

    if YPixels<2*options.y_bg_size+200
        error('Not enough edge space to calibrate background offset!')
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
        offset(x_range,:) = XYFit.p00+XYFit.p10*x_range'+XYFit.p01*(1:YPixels);

        BgBoxNew1 = BgBox1-offset(x_range,y_range1);
        BgBoxNew2 = BgBox2-offset(x_range,y_range2);
        variance(i,:) = [var(BgBoxNew1(:)),var(BgBoxNew2(:))];
        
        residuals{i,1} = BgBoxNew1;
        residuals{i,2} = BgBoxNew2;
    end
    
    warning('off','backtrace')
    if any(variance>6)
        warning('Noticable background noise variance after cancellation: max = %4.2f, min = %4.2f.', ...
            max(variance(:)),min(variance(:)))
    end
    if any(abs(offset)>2)
        warning('Noticable background offset after subtraction: max = %4.2f, min = %4.2f.Please check imaging conditions.', ...
            max(offset(:)),min(offset(:)))
    end
    warning('on','backtrace')
end