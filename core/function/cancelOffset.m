function [offset, variance, residuals] = cancelOffset(signal, num_frames, options)
    arguments
        signal
        num_frames (1,1) double = 1
        options.region_width (1,1) double = 100
        options.warning (1,1) logical = true
        options.warning_thres_offset (1,1) double = 10
        options.warning_thres_var (1,1) double = 50
        options.warning_note (1, 1) string = ""
    end
    signal = mean(signal, 3);
    [x_pixels, y_pixels] = size(signal);
    x_size = x_pixels/num_frames;
    if y_pixels < 2*options.region_width + 200
        error('Not enough edge space to calibrate background offset!')
    end
    offset = zeros(x_pixels, y_pixels);
    variance = zeros(num_frames, 2);

    y_range1 = 1:options.region_width;
    y_range2 = y_pixels+(1-options.region_width:0);
    residuals = cell(num_frames,2);
    for i = 1:num_frames
        x_range = (i-1)*x_size+(1:x_size);
        bg_box1 = signal(x_range,y_range1);
        bg_box2 = signal(x_range,y_range2);
        [XOut1,YOut1,ZOut1] = prepareSurfaceData(x_range,y_range1',bg_box1');
        [XOut2,YOut2,ZOut2] = prepareSurfaceData(x_range,y_range2',bg_box2');
        XOut = [XOut1;XOut2];
        YOut = [YOut1;YOut2];
        ZOut = [ZOut1;ZOut2];
        XYFit = fit([XOut,YOut],ZOut,'poly11');

        % Background offset canceling with fitted plane
        offset(x_range,:) = XYFit.p00+XYFit.p10*x_range'+XYFit.p01*(1:y_pixels);

        res1 = bg_box1-offset(x_range,y_range1);
        res2 = bg_box2-offset(x_range,y_range2);
        variance(i,:) = [var(res1(:)),var(res2(:))];
        
        residuals{i,1} = res1;
        residuals{i,2} = res2;
    end
    
    if options.warning
        warning('off','backtrace')
        if any(variance>options.warning_thres_var)
            warning('%sNoticable background variance, max = %4.2f, min = %4.2f.', ...
                options.warning_note,max(variance(:)),min(variance(:)))
        end
        if any(abs(offset)>options.warning_thres_offset)
            warning('%sNoticable background offset, max = %4.2f, min = %4.2f.', ...
                options.warning_note,max(offset(:)),min(offset(:)))
        end
        warning('on','backtrace')
    end
end
