function [bestH, bestMatchedPoints, stitchedImg] = findTransformationMatrixRANSAC(imgPath1, imgPath2, matchedKeyPoints1, matchedKeyPoints2)
    img1 = imread(imgPath1);
    img2 = imread(imgPath2);
    maxInliers = 0;
    bestH = [];
    bestMatchedPoints = [];
    N = 10000; % Number of RANSAC experiments
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

    stitchedImg = stitchImages(img1, img2, inv(bestH));
    visualizeKeypointMatches(img1, img2, matchedKeyPoints1(bestMatchedPoints, :), matchedKeyPoints2(bestMatchedPoints, :), 'Keypoint Correspondences');
    figure('Name', 'Stitched Image', 'NumberTitle', 'off');
    imshow(stitchedImg);
    % disp(bestH);
    % disp(bestMatchedPoints);
end


function stitchedImg = stitchImages(img1, img2, H)
    % Use computeHomography and calculateCanvasSize logic to determine the canvas dimensions and offsets
    [canvasWidth, canvasHeight, xOffset, yOffset] = calculateCanvasSize(img1, img2, H);

    % Initialize the canvas with determined dimensions
    stitchedImg = zeros(canvasHeight, canvasWidth, 3, 'like', img1);

    % Place img1 on the canvas considering the xOffset and yOffset
    stitchedImg(yOffset + (1:size(img1, 1)), xOffset + (1:size(img1, 2)), :) = img1;

    % Inverse of H for mapping points from the canvas to img2
    H_inv = inv(H);

    % Iterate over the canvas to fill in pixels from img2
    for xCanvas = 1:canvasWidth
        for yCanvas = 1:canvasHeight
            % Map canvas coordinates back to img2 coordinates
            nonBaseImgPos = H_inv * [(xCanvas - xOffset); (yCanvas - yOffset); 1];
            nonBaseImgPos = nonBaseImgPos / nonBaseImgPos(3);

            xNonBase = round(nonBaseImgPos(1));
            yNonBase = round(nonBaseImgPos(2));

            % If the mapped point is within img2 bounds, copy its pixel value to the canvas
            if xNonBase >= 1 && xNonBase <= size(img2, 2) && yNonBase >= 1 && yNonBase <= size(img2, 1)
                stitchedImg(yCanvas, xCanvas, :) = img2(yNonBase, xNonBase, :);
            end
        end
    end
end

function [canvasWidth, canvasHeight, xOffset, yOffset] = calculateCanvasSize(img1, img2, H)
    % This function should be similar to your initial logic for calculating the canvas size
    % Calculate transformed corners of img2
    [h1, w1, ~] = size(img1);
    [h2, w2, ~] = size(img2);
    cornersImg2 = [1, w2, w2, 1; 
                   1, 1, h2, h2; 
                   1, 1, 1, 1];
    transformedCorners = H * cornersImg2;
    transformedCorners = bsxfun(@rdivide, transformedCorners(1:2,:), transformedCorners(3,:));

    % Determine canvas bounds and offsets
    allX = [1, w1, transformedCorners(1,:)];
    allY = [1, h1, transformedCorners(2,:)];
    minX = floor(min(allX));
    maxX = ceil(max(allX));
    minY = floor(min(allY));
    maxY = ceil(max(allY));

    canvasWidth = round(maxX - minX + 1);
    canvasHeight = round(maxY - minY + 1);
    xOffset = round(1 - minX);
    yOffset = round(1 - minY);
end


function visualizeKeypointMatches(img1, img2, matchedKeyPoints1, matchedKeyPoints2, titleStr)
    imshow([img1, img2]); % Show images side by side
    hold on;
    for i = 1:size(matchedKeyPoints1, 1)
        % Adjust x-coordinate for keypoints in the second image
        pt2Adjusted = matchedKeyPoints2(i, :);
        pt2Adjusted(1) = pt2Adjusted(1) + size(img1, 2);
        
        % Draw line between matched keypoints
        line([matchedKeyPoints1(i, 1), pt2Adjusted(1)], [matchedKeyPoints1(i, 2), pt2Adjusted(2)], 'Color', 'yellow');
    end
    title(titleStr);
    hold off;
end

function H = computeHomography(srcPoints, dstPoints)
    A = [];
    for i = 1:size(srcPoints, 1)
        x = srcPoints(i, 1);
        y = srcPoints(i, 2);
        xPrime = dstPoints(i, 1);
        yPrime = dstPoints(i, 2);
        A = [A; x, y, 1, 0, 0, 0, -x*xPrime, -y*xPrime, -xPrime];
        A = [A; 0, 0, 0, x, y, 1, -x*yPrime, -y*yPrime, -yPrime];
    end
    [~, ~, V] = svd(A);
    H = reshape(V(:,end), [3, 3])';
end
