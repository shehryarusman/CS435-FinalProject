imgPath1 = 'image3.jpeg';
imgPath2 = 'image4.jpg';

% Hard-coded correspondences
% points_img1 = [818, 105; 1241, 990; 866, 792; 758, 1011];
% points_img2 = [230, 84; 641, 987; 305, 798; 179, 1029];
% 
% displayImageCorrespondences(imgPath1, imgPath2, points_img1, points_img2);
% 
% computeAndBlendImages(imgPath1, imgPath2, points_img1, points_img2);

pyramids1 = createImagePyramids(imgPath1);
keypoints1 = findScaleSpaceExtremas(pyramids1, imgPath1);
 
pyramids2 = createImagePyramids(imgPath2);
keypoints2 = findScaleSpaceExtremas(pyramids2, imgPath2);

[matchedKeyPoints1, matchedKeyPoints2] = keypointMatchingAndVisualization(imgPath1, imgPath2, keypoints1, keypoints2);
close all;
[bestH, bestMatchedPoints, stitchedImg] = findTransformationMatrixRANSAC(imgPath1, imgPath2, matchedKeyPoints1, matchedKeyPoints2);