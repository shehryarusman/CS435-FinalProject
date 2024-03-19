% Load and display the first image
img1 = imread('img1.jpg');
figure;
imshow(img1);
title('Select points on img1 and press Enter when done');

% Use data cursor mode to pick points
datacursormode on;
pause; % Wait for you to press Enter in the command window

% Extract positions of selected points for img1
dcm_obj = datacursormode(gcf);
c_info = getCursorInfo(dcm_obj);
points_img1 = zeros(length(c_info), 2);
for i = 1:length(c_info)
    points_img1(i,:) = c_info(i).Position;
end

% Load and display the second image
img2 = imread('img2.jpg');
figure;
imshow(img2);
title('Select points on img2 and press Enter when done');

% Repeat the process for the second image
datacursormode on;
pause; % Wait for you to press Enter in the command window

% Extract positions of selected points for img2
dcm_obj = datacursormode(gcf);
c_info = getCursorInfo(dcm_obj);
points_img2 = zeros(length(c_info), 2);
for i = 1:length(c_info)
    points_img2(i,:) = c_info(i).Position;
end

% Now, points_img1 and points_img2 contain the selected points' coordinates.
