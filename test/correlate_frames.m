function [R, R_prime,V_prime] = correlate_frames(points1, V1, V2, points2)
    % Input:
    % points1, points2: Nx2 matrices of points for the first and second frames
    % V1, V2: lattice vectors (2x1) for the first frame
    %
    % Output:
    % V: 2x2 transformation matrix
    % points1_ordered, points2_ordered: Ordered points after translation

    % Step 1: Find the centroid (center) of points in the first and second frames
    R = mean(points1, 1);
    R_prime = mean(points2, 1);

    % Step 2: Translate points1 and points2 to their respective origins (centroids)
    points1_translated = points1 - R;
    points2_translated = points2 - R_prime;

    % Step 3: Reorder points based on the sum of distances between points within the same set
    points1_ordered = order_points_by_internal_distances(points1_translated);
    points2_ordered = order_points_by_internal_distances(points2_translated);

    % Step 4: Use linear regression to find the best 2x2 matrix V such that
    % points1_ordered * V ≈ points2_ordered
    % Solve the normal equations for least squares:
    V_r = (points1_ordered' * points1_ordered) \ (points1_ordered' * points2_ordered);
    V = [V1;V2];
    V_prime= V*V_r;
    error = (points1_ordered /V *V_prime) - points2_ordered;

    % Display the results
    disp('Best transformation matrix V:');
    disp(V_prime);
    disp('Error');
    disp(error);
end

% Helper function to order points based on the sum of distances to other points
function points_ordered = order_points_by_internal_distances(points)
    N = size(points, 1);  % Number of points
    distances = zeros(N, 1);
    
    % Calculate the sum of distances between each point and the others
    for i = 1:N
        for j = 1:N
            if i ~= j
                distances(i) = distances(i) + norm(points(i,:) - points(j,:));
            end
        end
    end
    
    % Sort the points based on the sum of distances (ascending order)
    [~, order] = sort(distances);
    points_ordered = points(order, :);
end