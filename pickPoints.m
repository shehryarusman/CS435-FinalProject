img1 = imread('img1.jpg');
figure;
imshow(img1);
title('Select points on img1 and press Enter when done');

datacursormode on;
pause;

dcm_obj = datacursormode(gcf);
c_info = getCursorInfo(dcm_obj);
points_img1 = zeros(length(c_info), 2);
for i = 1:length(c_info)
    points_img1(i,:) = c_info(i).Position;
end

img2 = imread('img2.jpg');
figure;
imshow(img2);
title('Select points on img2 and press Enter when done');

datacursormode on;
pause; 

dcm_obj = datacursormode(gcf);
c_info = getCursorInfo(dcm_obj);
points_img2 = zeros(length(c_info), 2);
for i = 1:length(c_info)
    points_img2(i,:) = c_info(i).Position;
end