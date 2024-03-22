function pyramids = createImagePyramids(imagePath)
    disp("pyramid");
    originalImg = imread(imagePath);
    grayImg = im2double(rgb2gray(originalImg));

    % Hyperparameters
    numOctaves = 4; % Number of octaves
    numScales = 5;  % Number of scales per octave
    sigma0 = 1.6;   % Initial sigma value
    k = sqrt(2);    % Scale multiplier

    pyramids = cell(numOctaves, numScales);

    pyramidsFigure = figure('Name', 'Scale-Space Image Pyramids');
    figure(pyramidsFigure)
    
    for n = 1:numOctaves
        for m = 1:numScales
            sigma = (2^(n-1)) * (k^(m-1)) * sigma0;

            filterSize = ceil(3*sigma);

            if mod(filterSize, 2) == 0
                filterSize = filterSize + 1;
            end

            smoothedImg = imgaussfilt(grayImg, sigma, 'FilterSize', filterSize);

            pyramids{n, m} = smoothedImg;

            subplotIndex = (n-1)*numScales + m;

            subplot(numOctaves, numScales, subplotIndex);
            imshow(smoothedImg);
            title(['Octave ', num2str(n), ', Scale ', num2str(m), ', \sigma = ', sprintf('%.2f', sigma)]);
        end

        if n < numOctaves
            grayImg = grayImg(1:2:end, 1:2:end); 
        end
    end
    [pathstr, name, ~] = fileparts(imagePath);
    outputPath = fullfile(pathstr, [name, '_pyramids.png']);
    
    if exist('exportgraphics', 'file')
        exportgraphics(pyramidsFigure, outputPath);
    else
        saveas(pyramidsFigure, outputPath);
    end
end