function keypoints = findScaleSpaceExtremas(pyramids, imagePath)
    disp("maximas");
    originalImg = imread(imagePath);
    numOctaves = size(pyramids, 1);
    numScales = size(pyramids, 2);
    estimatedKeypoints = 10000;
    keypoints = zeros(estimatedKeypoints, 5);
    contrastThreshold = 0.1;
    patchSize = 5; 
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
                    centerValue = DoGs{n, m}(y, x);
                    
                    neighborhood3D = cat(3, DoGs{n, m-1}(y-1:y+1, x-1:x+1), DoGs{n, m}(y-1:y+1, x-1:x+1), DoGs{n, m+1}(y-1:y+1, x-1:x+1));
                    
                    neighborhood3D(2,2,2) = NaN;
                    
                    isMaxima = centerValue > max(neighborhood3D(:), [], 'omitnan');
                    
                    if isMaxima
                        locX = x * 2^(n-1);
                        locY = y * 2^(n-1);
                        keypoints(keypointIndex, :) = [locX, locY, n, m, centerValue];
                        keypointIndex = keypointIndex + 1;
                    end
                end
            end
        end
    end
    
    keypoints = keypoints(1:keypointIndex-1, :);

    disp("done");
    mainFig = figure;
    figure(mainFig);
    imshow(originalImg); hold on;
    plot(keypoints(:,1), keypoints(:,2), 'ro', 'MarkerSize', 5);
    title('All Detected Keypoints');
    hold off;
    
    [pathstr, name, ~] = fileparts(imagePath);
    allKeypointsPath = fullfile(pathstr, [name, '_all_keypoints.png']);
    if exist('exportgraphics', 'file')
        exportgraphics(mainFig, allKeypointsPath);
    else
        saveas(mainFig, allKeypointsPath);
    end

    keypoints = filterKeypoints(keypoints, pyramids, contrastThreshold, patchSize);

    disp("done2");
    keypointsFigure = figure;
    figure(keypointsFigure);
    imshow(originalImg); hold on;
    plot(keypoints(:,1), keypoints(:,2), 'ro', 'MarkerSize', 5);
    title('Stable Keypoints After Filtering');
    hold off;

    stableKeypointsPath = fullfile(pathstr, [name, '_stable_keypoints.png']);
    if exist('exportgraphics', 'file')
        exportgraphics(keypointsFigure, stableKeypointsPath);
    else
        saveas(keypointsFigure, stableKeypointsPath);
    end
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

        if x <= borderThreshold || x >= size(baseImage, 2) - borderThreshold || ...
           y <= borderThreshold || y >= size(baseImage, 1) - borderThreshold
            continue; 
        end

        if edges(round(y), round(x))
            continue;
        end
        
        octave = keypoints(i, 3);
        scale = keypoints(i, 4);
        locX = keypoints(i, 1);
        locY = keypoints(i, 2);
        
        adjustedLocX = round(locX / 2^(octave - 1));
        adjustedLocY = round(locY / 2^(octave - 1));
        
        scaleImg = pyramids{octave, scale}; 

        xMin = max(1, adjustedLocX - patchSize);
        xMax = min(size(scaleImg, 2), adjustedLocX + patchSize);
        yMin = max(1, adjustedLocY - patchSize);
        yMax = min(size(scaleImg, 1), adjustedLocY + patchSize);
        
        patch = scaleImg(yMin:yMax, xMin:xMax);
        if std2(patch) < contrastThreshold
            continue;
        end

        isStable(i) = true;
    end
    
    filteredKeypoints = keypoints(isStable, :);
end
