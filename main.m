imgPath1 = 'img1.jpg';
imgPath2 = 'img2.jpg';

% imgPath1 = 'img3.jpeg';
% imgPath2 = 'img4.jpg';

% Hard-coded correspondences 1 and 2
points_img1 = [818, 105; 1241, 990; 866, 792; 758, 1011];
points_img2 = [230, 84; 641, 987; 305, 798; 179, 1029];

% Hard-coded correspondences 3 and 4
% points_img1 = [689, 703; 1465.2, 888; 714.84, 160.95; 575.72, 575.72;];
% points_img2 = [336, 712; 1057.83, 831.39; 361.12, 128.76; 213.86, 571.28;];

displayImageCorrespondences(imgPath1, imgPath2, points_img1, points_img2);
 
computeAndBlendImages(imgPath1, imgPath2, points_img1, points_img2);

% pyramids1 = createImagePyramids(imgPath1);
% keypoints1 = findScaleSpaceExtremas(pyramids1, imgPath1);
% 
% pyramids2 = createImagePyramids(imgPath2);
% keypoints2 = findScaleSpaceExtremas(pyramids2, imgPath2);
% 
% [matchedKeyPoints1, matchedKeyPoints2] = keypointMatchingAndVisualization(imgPath1, imgPath2, keypoints1, keypoints2);
% 
% [bestH, bestMatchedPoints, stitchedImg] = findTransformationMatrixRANSAC(imgPath1, imgPath2, matchedKeyPoints1, matchedKeyPoints2);