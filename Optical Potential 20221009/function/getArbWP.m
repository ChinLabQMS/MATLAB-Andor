function T = getArbWP(A,B)
% A is the induced phase difference between two axis
% B is the angle of rotation
    T = [cos(A/2)+1i*cos(2*B)*sin(A/2),1i*sin(2*B)*sin(A/2);
        1i*sin(2*B)*sin(A/2),cos(A/2)-1i*cos(2*B)*sin(A/2)];
end