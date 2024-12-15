function [xc, yc, xw, yw, gfitx, gfity, signal_x, signal_y] = fitGaussXY(signal, x_range, y_range, varargin)
    arguments
        signal
        x_range {mustBeValidRange(signal, 1, x_range)} = 1: size(signal, 1)
        y_range {mustBeValidRange(signal, 2, y_range)} = 1: size(signal, 2)
    end
    arguments (Repeating)
        varargin
    end
    signal_x = sum(signal, 2);
    signal_y = sum(signal, 1);
    gfitx = fitGauss1D(signal_x(:)', x_range, varargin{:});
    gfity = fitGauss1D(signal_y(:)', y_range, varargin{:});
    xc = gfitx.x0;
    yc = gfity.x0;
    xw = gfitx.s1;
    yw = gfity.s1;
end
