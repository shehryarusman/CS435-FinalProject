function keypoints = findScaleSpaceExtremas(pyramids, imagePath)
    disp("maximas");
    originalImg = imread(imagePath);
    numOctaves = size(pyramids, 1);
    numScales = size(pyramids, 2);
    estimatedKeypoints = 10000;
    keypoints = zeros(estimatedKeypoints, 5);
    contrastThreshold = 0.1;
    patchSize = 4; 
    keypointIndex = 1;

    DoGs = cell(numOctaves, numScales-1);
    for n = 1:numOctaves
        for m = 1:numScales-1
            DoGs{n, m} = pyramids{n, m+1} - pyramids{n, m};
        end
    end
    
    for n = 1:numOctaves
        for m = 2:numScales-2
            for y = 2:size(DoGs{n, m}, 1)-1
                for x = 2:size(DoGs{n, m}, 2)-1
                    centerValue = DoGs{n, m}(y, x); % Current pixel value
                    
                    % Extract the 3x3x3 neighborhood including the center pixel
                    neighborhood3D = cat(3, DoGs{n, m-1}(y-1:y+1, x-1:x+1), DoGs{n, m}(y-1:y+1, x-1:x+1), DoGs{n, m+1}(y-1:y+1, x-1:x+1));
                    
                    % Exclude the center pixel by setting it to NaN temporarily for comparison
                    neighborhood3D(2,2,2) = NaN;
                    
                    % Check if centerValue is a maxima
                    isMaxima = centerValue > max(neighborhood3D(:), [], 'omitnan');
                    
                    if isMaxima
                        locX = x * 2^(n-1); % Adjust location to original image's scale
                        locY = y * 2^(n-1);
                        keypoints(keypointIndex, :) = [locX, locY, n, m, centerValue];
                        keypointIndex = keypointIndex + 1;
                    end
                end
            end
        end
    end
    
    keypoints = keypoints(1:keypointIndex-1, :); % Trim to filled size

    disp("done");
    mainFig = figure;
    figure(mainFig);
    imshow(originalImg); hold on;
    plot(keypoints(:,1), keypoints(:,2), 'ro', 'MarkerSize', 5);
    title('All Detected Keypoints');
    hold off;

    % Apply filtering to remove unstable keypoints
    keypoints = filterKeypoints(keypoints, pyramids, contrastThreshold, patchSize);

    disp("done2");
    keypointsFigure = figure;
    figure(keypointsFigure);
    imshow(originalImg); hold on;
    plot(keypoints(:,1), keypoints(:,2), 'ro', 'MarkerSize', 5);
    title('Stable Keypoints After Filtering');
    hold off;
end

function filteredKeypoints = filterKeypoints(keypoints, pyramids, contrastThreshold, patchSize)
    disp("filtering");
    baseImage = pyramids{1,1};
    if size(baseImage, 3) == 3
        edges = edge(rgb2gray(baseImage), 'Canny');
    else
        edges = edge(baseImage, 'Canny');
    end
    
    isStable = false(size(keypoints, 1), 1);

    for i = 1:size(keypoints, 1)
        x = keypoints(i, 1);
        y = keypoints(i, 2);
        
        borderThreshold = patchSize;

        % Skip keypoints too close to the border
        if x <= borderThreshold || x >= size(baseImage, 2) - borderThreshold || ...
           y <= borderThreshold || y >= size(baseImage, 1) - borderThreshold
            continue; % Too close to the border
        end

        if edges(round(y), round(x))
            continue; % Skip edge keypoints
        end
        
        octave = keypoints(i, 3);
        scale = keypoints(i, 4);
        locX = keypoints(i, 1);
        locY = keypoints(i, 2);
        
        % Adjust locations to the scale of the image at the detected octave
        % This adjustment is crucial if your keypoints locations (locX, locY) 
        % are in terms of the original image size
        adjustedLocX = round(locX / 2^(octave - 1));
        adjustedLocY = round(locY / 2^(octave - 1));
        
        % Using the image at the detected scale for contrast check
        scaleImg = pyramids{octave, scale}; 

        % Ensure patch extraction does not exceed image boundaries
        xMin = max(1, adjustedLocX - patchSize);
        xMax = min(size(scaleImg, 2), adjustedLocX + patchSize);
        yMin = max(1, adjustedLocY - patchSize);
        yMax = min(size(scaleImg, 1), adjustedLocY + patchSize);
        
        % Extract patch and calculate its standard deviation
        patch = scaleImg(yMin:yMax, xMin:xMax);
        if std2(patch) < contrastThreshold
            % Skip low contrast keypoints
            continue;
        end

        % Mark as stable if it passes both checks
        isStable(i) = true;
    end
    
    % Keep only stable keypoints
    filteredKeypoints = keypoints(isStable, :);
end
