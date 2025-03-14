function Value = wigner6j(j1,j2,j3,j4,j5,j6)
    warning('off','all')
    [~, Ans] = jj6j(j1,j2,j3,j4,j5,j6);
    warning('on','all')
    Value = Ans(7);
end