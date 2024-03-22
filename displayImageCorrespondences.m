function displayImageCorrespondences(imgPath1, imgPath2, points_img1, points_img2)
    img1 = imread(imgPath1);
    img2 = imread(imgPath2);

    height = max(size(img1, 1), size(img2, 1));
    width = size(img1, 2) + size(img2, 2);
    channels = size(img1, 3); 
    combined_img = zeros(height, width, channels, 'uint8');

    combined_img(1:size(img1, 1), 1:size(img1, 2), :) = img1;
    combined_img(1:size(img2, 1), size(img1, 2)+1:end, :) = img2;

    points_img2_adjusted = points_img2 + [size(img1, 2) * ones(size(points_img2, 1), 1) zeros(size(points_img2, 1), 1)];

    colors = [1 0 0; 0 1 0; 0 0 1; 1 1 0];

    KPColored = figure;
    figure(KPColored);
    imshow(combined_img); hold on;

    for i = 1:size(points_img1, 1)
        scatter(points_img1(i,1), points_img1(i,2), 50, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(i,:));
        scatter(points_img2_adjusted(i,1), points_img2_adjusted(i,2), 50, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(i,:));
    end
    hold off;

    [pathstr, name, ~] = fileparts(imgPath1);
    outputPath = fullfile(pathstr, [name, '_part1_correspondences.png']); 
    
    if exist('exportgraphics', 'file')
        exportgraphics(KPColored, outputPath);
    else
        saveas(KPColored, outputPath);
    end
    
    close(KPColored);
end
