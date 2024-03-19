function [bestH, bestMatchedPoints, stitchedImg] = findTransformationMatrixRANSAC(imgPath1, imgPath2, matchedKeyPoints1, matchedKeyPoints2)
    img1 = imread(imgPath1);
    img2 = imread(imgPath2);
    maxInliers = 0;
    bestH = [];
    bestMatchedPoints = [];
    N = 1000; % Number of RANSAC experiments
    tolerance = 5; % Tolerance in pixels

    for i = 1:N
        indices = randperm(size(matchedKeyPoints1, 1), 4);
        points1 = matchedKeyPoints1(indices, :);
        points2 = matchedKeyPoints2(indices, :);

        H = computeHomography(points1, points2);

        inliers = 0;
        matchedPoints = [];
        
        for j = 1:size(matchedKeyPoints1, 1)
            point1 = [matchedKeyPoints1(j, 1:2), 1]';
            projectedPoint2 = H * point1;
            projectedPoint2 = projectedPoint2 / projectedPoint2(3);

            point2 = [matchedKeyPoints2(j,1:2), 1]';
            distance = norm(projectedPoint2(1:2) - point2(1:2));

            if distance < tolerance
                inliers = inliers + 1;
                matchedPoints = [matchedPoints; j];
            end
        end

        if inliers > maxInliers
            maxInliers = inliers;
            bestH = H;
            bestMatchedPoints = matchedPoints;
        end
    end

    stitchedImg = stitchImages(img1, img2, bestH);
    visualizeKeypointMatches(img1, img2, matchedKeyPoints1(bestMatchedPoints, :), matchedKeyPoints2(bestMatchedPoints, :), 'Keypoint Correspondences');
    figure('Name', 'Stitched Image', 'NumberTitle', 'off');
    imshow(stitchedImg);
end


function stitchedImg = stitchImages(img1, img2, H)
    % Convert the homography matrix to a projective transformation object
    tform = projective2d(H');
    
    % Determine the output limits for both images
    [xlim, ylim] = outputLimits(tform, [1 size(img2, 2)], [1 size(img2, 1)]);
    
    % Find the minimum and maximum output limits 
    xMin = min([1; xlim(:)]);
    xMax = max([size(img1, 2); xlim(:)]);
    yMin = min([1; ylim(:)]);
    yMax = max([size(img1, 1); ylim(:)]);
    
    % Width and height of the panorama
    width  = round(xMax - xMin);
    height = round(yMax - yMin);
    
    % Initialize the "empty" panorama
    panorama = zeros([height width 3], 'like', img1);
    
    % Create a 2d spatial reference object defining the size of the panorama
    xLimits = [xMin xMax];
    yLimits = [yMin yMax];
    panoramaView = imref2d([height width], xLimits, yLimits);
    
    % Place the first image in the panorama
    panorama = imwarp(img1, projective2d(eye(3)), 'OutputView', panoramaView);
    
    % Place the second image in the panorama
    panorama = max(panorama, imwarp(img2, tform, 'OutputView', panoramaView));
    
    stitchedImg = panorama;
end


function visualizeKeypointMatches(img1, img2, matchedKeyPoints1, matchedKeyPoints2, titleStr)
    % Combine images side-by-side
    [height1, width1, ~] = size(img1);
    [height2, width2, ~] = size(img2);
    totalWidth = width1 + width2;
    maxHeight = max(height1, height2);
    combinedImage = zeros(maxHeight, totalWidth, 3, 'like', img1);
    combinedImage(1:height1, 1:width1, :) = img1;
    combinedImage(1:height2, width1+1:end, :) = img2;

    % Adjust matchedKeyPoints2 for the combined image
    matchedKeyPoints2Adjusted = matchedKeyPoints2;
    matchedKeyPoints2Adjusted(:, 1) = matchedKeyPoints2(:, 1) + width1;

    % Draw lines for matches
    for i = 1:size(matchedKeyPoints1, 1)
        pt1 = matchedKeyPoints1(i, :);
        pt2 = matchedKeyPoints2Adjusted(i, :);
        combinedImage = insertShape(combinedImage, 'Line', [pt1 pt2], 'LineWidth', 2, 'Color', 'yellow');
    end

    % Display the result
    figure('Name', titleStr, 'NumberTitle', 'off');
    imshow(combinedImage);
    title(titleStr);
end


function H = computeHomography(srcPoints, dstPoints)
    A = [];
    for i = 1:size(srcPoints, 1)
        X = srcPoints(i, 1);
        Y = srcPoints(i, 2);
        x = dstPoints(i, 1);
        y = dstPoints(i, 2);
        A = [A; X, Y, 1, 0, 0, 0, -x*X, -x*Y, -x;
                0, 0, 0, X, Y, 1, -y*X, -y*Y, -y];
    end
    [~, ~, V] = svd(A);
    H = reshape(V(:, end), 3, 3)';
end
