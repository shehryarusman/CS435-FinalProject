function [matchedKeyPoints1, matchedKeyPoints2] = keypointMatchingAndVisualization(imgPath1, imgPath2, keypoints1, keypoints2)
    img1 = imread(imgPath1);
    img2 = imread(imgPath2);

    patchSize = 4;
    descriptors1 = extractDescriptors(img1, keypoints1, patchSize);
    descriptors2 = extractDescriptors(img2, keypoints2, patchSize);

    maxDistance = 100;
    matches = matchKeypoints(descriptors1, descriptors2, maxDistance);

    if isempty(matches)
        disp('No matches found.');
        return;
    else
        disp(['Found ', num2str(size(matches, 1)), ' matches.']);
    end

    matchedKeyPoints1 = keypoints1(matches(:,1),:);
    matchedKeyPoints2 = keypoints2(matches(:,2),:);

    visualizeMatches(img1, img2, matchedKeyPoints1, matchedKeyPoints2, 'Matched Keypoints Visualization');
end

function descriptors = extractDescriptors(image, keypoints, patchSize)
    numKeypoints = size(keypoints, 1);
    descriptorLength = (2 * patchSize + 1)^2 * 3; % For a 9x9 patch in an RGB image
    descriptors = zeros(numKeypoints, descriptorLength);
    for i = 1:numKeypoints
        locX = round(keypoints(i, 1));
        locY = round(keypoints(i, 2));
        minX = max(1, locX - patchSize);
        maxX = min(size(image, 2), locX + patchSize);
        minY = max(1, locY - patchSize);
        maxY = min(size(image, 1), locY + patchSize);
        patch = image(minY:maxY, minX:maxX, :);
        descriptors(i, :) = reshape(patch, 1, []);
    end
end

function matches = matchKeypoints(descriptors1, descriptors2, maxDistance)
    matchesC1 = NaN(size(descriptors1, 1), 3);
    matchesC2 = NaN(size(descriptors2, 1), 3);
    C = [];

    for i = 1:size(descriptors1, 1)
        distances = sqrt(sum((descriptors2 - descriptors1(i, :)).^2, 2));
        [minDistance, idx] = min(distances);
        
        matchesC1(i, :) = [i, idx, minDistance];
    end

    for j = 1:size(descriptors2, 1)
        distances = sqrt(sum((descriptors1 - descriptors2(j, :)).^2, 2));
        [minDistance, idx] = min(distances);
        
        matchesC2(j, :) = [j, idx, minDistance];
    end
    
    for i = 1:size(matchesC1, 1)
        keypointIdx1 = matchesC1(i, 1);
        keypointIdx2 = matchesC1(i, 2);
        
        matchInC2 = matchesC2(matchesC2(:, 1) == keypointIdx2, :);
        
        if ~isempty(matchInC2) && matchInC2(2) == keypointIdx1
            C = [C; keypointIdx1, keypointIdx2, matchesC1(i, 3)];
        end
    end
    
    filteredC = C(C(:, 3) <= maxDistance, 1:2);
    
    matches = filteredC;
end

function visualizeMatches(img1, img2, keypoints1, keypoints2, titleStr)
    figure('Name', titleStr, 'NumberTitle', 'off');
    ax = axes;
    showMatchedFeatures(img1, img2, keypoints1(:,1:2), keypoints2(:,1:2), 'montage', 'Parent', ax);
    title(ax, titleStr);

end
