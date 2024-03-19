function computeAndBlendImages(baseImgPath, nonBaseImgPath, basePoints, nonBasePoints)
    baseImg = imread(baseImgPath);
    nonBaseImg = imread(nonBaseImgPath);

    H = computeHomography(nonBasePoints, basePoints);

    [canvasWidth, canvasHeight, xOffset, yOffset] = calculateCanvasSize(baseImg, nonBaseImg, H);

    canvas = zeros(canvasHeight, canvasWidth, 3, 'like', baseImg);

    canvas(yOffset + (1:size(baseImg, 1)), xOffset + (1:size(baseImg, 2)), :) = baseImg;

    H_inv = inv(H);

    for xCanvas = 1:canvasWidth
        for yCanvas = 1:canvasHeight
            nonBaseImgPos = H_inv * [(xCanvas - xOffset); (yCanvas - yOffset); 1];
            nonBaseImgPos = nonBaseImgPos / nonBaseImgPos(3);

            xNonBase = round(nonBaseImgPos(1));
            yNonBase = round(nonBaseImgPos(2));

            if xNonBase >= 1 && xNonBase <= size(nonBaseImg, 2) && yNonBase >= 1 && yNonBase <= size(nonBaseImg, 1)
                if all(nonBaseImg(yNonBase, xNonBase, :) > 0)
                    canvas(yCanvas, xCanvas, :) = nonBaseImg(yNonBase, xNonBase, :);
                end
            end
        end
    end

    blendedImg = figure;
    figure(blendedImg);
    imshow(canvas);
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
