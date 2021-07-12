function Features = GenFeatures(NormedStack,sigma,FiltDirGD,FiltLG,TopHatSizes,EntropySizes)
% Input:
% NormedStack = 3d input image, normalized
% sigma = standard deviation for gaussian derivatives
% FildDirGD = nx3 matrix of integers containing the order and direction of
% gaussian derivative filters. e.g. 2,3,1 is equivalent to 2. order
% derivative in y-, 3. order derivative in x- and 1. order derivative in
% z-direction. Different lines account for the usage of multiple
% combinations.
% FiltLG =  Cell of size 1xn each cell containing a different axb sized
% matrix containing the values of the laguerre gaussian polynomials used
% for convulation/filtering.
% TopHatSizes = Filter sizes used for top hat transformation. 1xn sized
% vector of integers.
% EntropySizes = Filter sizes used for entropy filtering. 1xn sized
% vector of integers

% Output:
% Features = nxm sized normalized feature matrix. n = width*height of
% image, m = number of features.

% Generate features:
% Allocate variable containing features:
Features = zeros(size(NormedStack,1), size(NormedStack,2),length(sigma)*size(FiltDirGD,1)+length(FiltLG) +2 * length(FiltLG)*length(sigma));
% Generate features:
% gaussian derivaties:
count = 0;
count2 = 0;
for i = sigma
    count2 = count2 +1;
    for j = 1:size(FiltDirGD,1)
        count = count+1;
        % Direction of orders: [y,x,z]
        [tmp,~] = gfilter(NormedStack,sigma(count2),FiltDirGD(j,:));
        Features(:,:,count) = max(tmp,[],3);
    end
end

% Laguerre gaussian:
NormedStackProj = max(NormedStack,[],3);
% figure; imshow(NormedStackProj)
for i = 1:length(FiltLG)
    count = count+1;
    Features(:,:,count) = imfilter(NormedStackProj, FiltLG{i},'symmetric','same');
end

% Laguerre gaussian of derivatives: xy-direction
count2 = 0;
for i = sigma
    count2 = count2 +1;
    % Direction of orders: [y,x,z]
    [tmp,~] = gfilter(NormedStack,sigma(count2),[1,1,0]);
    tmpproj = max(tmp,[],3);
    for j = 1:length(FiltLG)
        count = count + 1;
        Features(:,:,count) = imfilter(tmpproj, FiltLG{j},'symmetric','same');
    end
    
end

% Laguerre gaussian of derivatives: z-direction
count2 = 0;
for i = sigma
    count2 = count2 +1;
    % Direction of orders: [y,x,z]
    [tmp,~] = gfilter(NormedStack,sigma(count2),[0,0,1]);
    tmpproj = max(tmp,[],3);
    for j = 1:length(FiltLG)
        count = count + 1;
        Features(:,:,count) = imfilter(tmpproj, FiltLG{j},'symmetric','same');
    end
end

% Laguerre gaussian of coherency image:
CohIm = ImageCoherency3D(NormedStack,5);
CohIm = min(CohIm, [], 3);
for i = 1:length(FiltLG)
    count = count + 1;
    Features(:,:,count) = imfilter(CohIm, FiltLG{i},'symmetric','same');
end

% Top hat filter:
%Sizes = [3,4,5,7,9,13,15,18];
for i = 1:length(TopHatSizes)
    count = count + 1;
    se = strel('disk',TopHatSizes(i));
    Features(:,:,count) = imtophat(NormedStackProj,se);
    %         figure
    %         imshow(Features(:,:,count),[])
end

% entropy filter:
%Sizes = [3,5,7,9,13,17];
for i = 1:length(EntropySizes)
    count = count + 1;
    se = strel('disk',EntropySizes(i));
    Features(:,:,count) =  entropyfilt(NormedStackProj,se.Neighborhood);
    %         figure
    %         imshow(Features(:,:,count),[])
end

% Number of features
NumFeatures = size(Features,3);
% Normalize Features:
for i = 1:NumFeatures
    tmp = Features(:,:,i);
    tmp = (tmp- mean(tmp(:)))./std(tmp(:));
    Features(:,:,i) = tmp;
end