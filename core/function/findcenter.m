function [centroids] = findcenter(image, thresh_percent)
    arguments
        image (:, :, :) double
        thresh_percent (1, 1) double = 0.15
    end

    % set a threshold
    threshold_value = thresh_percent*max(image(:));

    % label connected components
    labeled_image = image > threshold_value;
    % find centroids
    stats = regionprops(labeled_image, ["Centroid", "Area"]);
    centroids = cat(1, stats.Centroid);
    areas = cat(1, stats.Area);

    % Filter based on area
    area_thres = 1;
    idx = areas > area_thres;
    centroids = centroids(idx, :);
    threshold_dis = 40;  % Distance threshold
    % Get the number of centroids
    N = size(centroids, 1);
    
    % Find pairwise distances between centroids
    D = pdist2(centroids, centroids);
    
    % Initialize a logical array to keep track of merged centroids
    merged = false(N, 1);
    
    % Loop over all centroids to check distances
    for i = 1:N
        if ~merged(i)
            % Find centroids that are within the threshold distance from centroid i
            close_idx = find(D(i, :) < threshold_dis & D(i, :) > 0);  % Exclude self (distance > 0)
            
            % If any centroids are close, compute the center of those centroids
            if ~isempty(close_idx)
                % Include the current centroid in the group
                group_idx = [i, close_idx];
                
                % Compute the mean (center) of the group of close centroids
                group_center = mean(centroids(group_idx, :), 1);
                
                % Replace the centroids in the group with the center
                centroids(group_idx, :) = repmat(group_center, length(group_idx), 1);
                
                % Mark the centroids as merged
                merged(group_idx) = true;
            end
        end
    end
    % Remove duplicate centroids (rows with the same coordinates)
    centroids = unique(centroids, 'rows');

    figure;
    imshow(image,[],'InitialMagnification','fit')
    title('Detected Bright Spots- centroids')
    hold
    plot(centroids(:,1),centroids(:,2),'r+','MarkerSize',10','LineWidth',2);
    hold off
end