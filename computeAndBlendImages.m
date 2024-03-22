function blendedImg = computeAndBlendImages(baseImgPath, nonBaseImgPath, basePoints, nonBasePoints)
    baseImg = imread(baseImgPath);
    nonBaseImg = imread(nonBaseImgPath);

    H = computeHomography(nonBasePoints, basePoints);
    
    % Compute canvas size and offsets
    [canvasWidth, canvasHeight, xOffset, yOffset] = calculateCanvasSize(baseImg, nonBaseImg, H);

    canvas = zeros(canvasHeight, canvasWidth, 3, 'like', baseImg);
    baseImgMask = false(canvasHeight, canvasWidth);
    nonBaseImgMask = false(canvasHeight, canvasWidth);

    % Place base image on canvas
    baseXRange = (1:size(baseImg,2)) + xOffset;
    baseYRange = (1:size(baseImg,1)) + yOffset;
    canvas(baseYRange, baseXRange, :) = baseImg;
    baseImgMask(baseYRange, baseXRange) = true;
    
    % Transform and place non-base image on a separate canvas
    nonBaseCanvas = zeros(size(canvas), 'like', canvas);
    for xCanvas = 1:canvasWidth
        for yCanvas = 1:canvasHeight
            nonBaseImgPos = H \ [xCanvas - xOffset; yCanvas - yOffset; 1];
            nonBaseImgPos = nonBaseImgPos / nonBaseImgPos(3);

            xNonBase = round(nonBaseImgPos(1));
            yNonBase = round(nonBaseImgPos(2));

            if xNonBase >= 1 && xNonBase <= size(nonBaseImg, 2) && yNonBase >= 1 && yNonBase <= size(nonBaseImg, 1)
                nonBaseCanvas(yCanvas, xCanvas, :) = nonBaseImg(yNonBase, xNonBase, :);
                nonBaseImgMask(yCanvas, xCanvas) = true;
            end
        end
    end

    disp("next time");

    % Identify overlapping area
    overlapMask = baseImgMask & nonBaseImgMask;

    % Blend images in the overlapping region
    for x = 1:canvasWidth
        for y = 1:canvasHeight
            if overlapMask(y, x)
                alpha = calculateAlpha([x, y], overlapMask);
                canvas(y, x, :) = alpha * double(canvas(y, x, :)) + (1 - alpha) * double(nonBaseCanvas(y, x, :));
            elseif nonBaseImgMask(y, x)
                canvas(y, x, :) = nonBaseCanvas(y, x, :);
            end
        end
    end

    % Display the result
    blendedImg = figure;
    imshow(canvas);
end

function alpha = calculateAlpha(pixel, overlapMask)
    % Find the boundary of the overlapMask
    [rows, cols] = find(overlapMask);
    topLeft = [min(cols), min(rows)];
    bottomRight = [max(cols), max(rows)];
    
    % Calculate distances to the nearest edge in the overlap
    distanceToLeftEdge = pixel(1) - topLeft(1);
    distanceToRightEdge = bottomRight(1) - pixel(1);
    distanceToTopEdge = pixel(2) - topLeft(2);
    distanceToBottomEdge = bottomRight(2) - pixel(2);
    
    % Use the minimum distance to any edge
    minDistanceToEdge = min([distanceToLeftEdge, distanceToRightEdge, distanceToTopEdge, distanceToBottomEdge]);
    
    % Normalize the distance based on the maximum possible distance to an edge within the overlap
    % This maximum distance is half of the overlap's width or height, whichever is smaller
    maxDistance = min(bottomRight - topLeft) / 2;
    alpha = minDistanceToEdge / maxDistance;
    
    % Ensure alpha is in the range [0, 1]
    alpha = max(0, min(1, alpha));
end


function [canvasWidth, canvasHeight, xOffset, yOffset] = calculateCanvasSize(baseImg, nonBaseImg, H)
    [nonBaseHeight, nonBaseWidth, ~] = size(nonBaseImg);
    corners = [1, nonBaseWidth, nonBaseWidth, 1;
               1, 1, nonBaseHeight, nonBaseHeight;
               1, 1, 1, 1];
    transformedCorners = H * corners;
    transformedCorners(1:2, :) = transformedCorners(1:2, :) ./ transformedCorners(3, :);

    % Determine the size of the canvas based on the transformed corners and the base image size
    minX = min([1, transformedCorners(1,:)]);
    maxX = max([size(baseImg, 2), transformedCorners(1,:)]);
    minY = min([1, transformedCorners(2,:)]);
    maxY = max([size(baseImg, 1), transformedCorners(2,:)]);
    canvasWidth = round(maxX - minX + 1);
    canvasHeight = round(maxY - minY + 1);
    xOffset = round(1 - minX);
    yOffset = round(1 - minY);
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
