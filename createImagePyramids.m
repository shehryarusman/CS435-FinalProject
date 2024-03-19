function pyramids = createImagePyramids(imagePath)
    disp("pyramid");
    % Load the image and convert it to grayscale
    originalImg = imread(imagePath);
    grayImg = im2double(rgb2gray(originalImg));

    % Hyperparameters
    numOctaves = 4; % Number of octaves
    numScales = 5;  % Number of scales per octave
    sigma0 = 1.6;   % Initial sigma value
    k = sqrt(2);    % Scale multiplier

    % Initialize pyramids cell array
    pyramids = cell(numOctaves, numScales);

    % Initialize figure for displaying all subimages
    pyramidsFigure = figure('Name', 'Scale-Space Image Pyramids');
    figure(pyramidsFigure)
    
    for n = 1:numOctaves
        for m = 1:numScales
            % Compute the sigma value for the current scale
            sigma = (2^(n-1)) * (k^(m-1)) * sigma0;

            % Compute the width of the Gaussian kernel
            filterSize = ceil(3*sigma);

            % Ensure the filter size is odd
            if mod(filterSize, 2) == 0
                filterSize = filterSize + 1;
            end

            % Apply Gaussian filter to smooth the image
            smoothedImg = imgaussfilt(grayImg, sigma, 'FilterSize', filterSize);

            % Store the smoothed image in the pyramids array
            pyramids{n, m} = smoothedImg;

            % Calculate the subplot index
            subplotIndex = (n-1)*numScales + m;

            % Display the smoothed image
            subplot(numOctaves, numScales, subplotIndex);
            imshow(smoothedImg);
            title(['Octave ', num2str(n), ', Scale ', num2str(m), ', \sigma = ', sprintf('%.2f', sigma)]);
        end

        % Prepare the image for the next octave by subsampling
        if n < numOctaves
            grayImg = grayImg(1:2:end, 1:2:end); % Subsample the image
        end
    end
end