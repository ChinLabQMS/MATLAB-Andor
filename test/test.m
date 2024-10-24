clear; clc;

DataPath = 'data/2024/10 October/20241001/gray_on_black_anchor=3_triangle_side1=100_side2=150_r=20.mat';
PatternPath = 'data/2024/10 October/20241001/anchor=3_triangle_side1=100_side2=150_r=20/template_r=20.bmp';

Data = load(DataPath, "Data").Data;
Signal = Preprocessor().processData(Data);

mean_Andor19330 = mean(Signal.Andor19330.Image, 3);
mean_Andor19331 = mean(Signal.Andor19331.Image, 3);
mean_Zelux = mean(Signal.Zelux.DMD, 3);
dmd = imread(PatternPath);

%%
figure
subplot(1, 3, 1)
Lattice.imagesc(mean_Andor19330)
subplot(1, 3, 2)
Lattice.imagesc(mean_Zelux)
subplot(1, 3, 3)
Lattice.imagesc(dmd)

%% Test pre-calibration

dmd_coor = [742, 741; 842, 741; 742, 891];
zelux_coor = [571, 646; 722, 501; 792, 870];
V1_zelux = [-23.20, -1.28];
V2_zelux = [10.54, 20.42];
V_zelux = [V1_zelux;V2_zelux];

[R_zelux, R_dmd,V_dmd] = correlate_frames(V1_zelux, V2_zelux, zelux_coor, dmd_coor);

text = (([792, 870] - R_zelux)/V_zelux)* V_dmd + R_dmd; 
disp(text);

%Transform index
% Assume mean_zelux is an n*m array
% Assume R_zelux is a 1x2 vector, e.g., [Rx, Ry]
% Assume V_zelux is a 2x2 transformation matrix

[n, m] = size(mean_Zelux);  % Get the size of mean_zelux
new_zelux = zeros(n, m);     % Initialize new_zelux to be the same size as mean_zelux

% Loop over each index (a, b) of the array
for a = 1:n
    for b = 1:m
        % Offset the index (a, b) by R_zelux
        new_index = ([a, b] - R_zelux)/V_zelux;  % This gives a 1x2 array

        % Apply the transformation V_zelux to the offset index
        transformed_index_dmd = new_index * V_dmd + R_dmd;  % Result is a 1x2 array

        % Now, use the transformed index to update new_zelux at (a, b)
        % Here you may need to use transformed_index to extract the correct value from mean_zelux
        % Assuming the transformed_index is used to set the value in new_zelux
        % You might want to limit the transformed index within the bounds
        row_idx = round(transformed_index_dmd(1));
        col_idx = round(transformed_index_dmd(2));

        % Check if the calculated indices are within bounds of mean_zelux
        if row_idx >= 1 && row_idx <= n && col_idx >= 1 && col_idx <= m
            % Assign the value from mean_zelux to new_zelux at (a, b)
            new_zelux(row_idx, col_idx) = mean_Zelux(a,b);
        else
            % If the transformed index is out of bounds, handle it (e.g., set to 0 or some default value)
            new_zelux(row_idx, col_idx) = 0;  % or any default value
        end
    end
end
disp(new_zelux(742, 891));
disp(mean_Zelux(792, 870));



%%
figure
subplot(1, 3, 1)
Lattice.imagesc(new_zelux)
subplot(1, 3, 2)
Lattice.imagesc(dmd)


