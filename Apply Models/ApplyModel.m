% Apply trained models to images and save the resulting data and an overlay
% image

clear all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parameters:

% Parameters for setting up the python environement:
% Path to the conda installation, e.g.'C:\ProgramData\anaconda3'
CondaPath = 'C:\ProgramData\anaconda3';
% Name of the conda environement to be used, e.g. 'root'
EnvName = 'UseFromMatlab';
% Name of a specified module to be load, e.g. 'sklearn'
ModuleName = 'sklearn';

% Models and scalings to be used:
% Image segmentation models:
% Name of the model to be load. Needs to be stored in the subfolder 
% "Trained Models".
ModelName = 'FinalModel MLP All pca99.9%.p';
% Name of the PCA coefficients to be load and number of features to be used. 
% Needs to be stored in the subfolder "Trained Models".
PCACoeffName = 'Scalings FinalModel MLP All pca99.9%.mat';

% Trained model to be used for differentiatig true positive objects from
% false positive objects.
% Needs to be stored in the subfolder "Classify TP and FP objects".
TP_FP_ClassifierName = 'Trained SVM MLP 99.9% PCA All Images.mat';

% Parameters for feature generation:
% Needs to be identical to the values of the training
% sigma = maximal standard deviation of gaussian filters -> also sets 
% window size of used filter
sigma =  [1,3,6];
% Top hat filter sizes used:
TopHatSizes = [3,4,5,7,9,13,15,18];
% Entropy filter sizes used:
EntropySizes = [3,5,7,9,13,17];


%%
% Do some initialisation:
% Get current m-file path:
FilePath = fileparts(mfilename('fullpath'));
addpath(FilePath)
% Add python environment:
addpath(strcat(FilePath,'\Add Python Environement'))
AddCondaEnvironementToMatlabPath(CondaPath,EnvName,ModuleName)

% Load respective model(s):
cd('D:\Auswertungskrams\CLSM PI\MLP Model using Python\MLP Model from sklearn\Apply Models\Trained Models')
cd(strcat(FilePath,'\Trained Models'))
% load model using pickle:
file = py.open(ModelName, "rb");
MLPModel = py.pickle.load(file);
file.close()
% load coefficients:
load(PCACoeffName)

% Load filterbank and add the respective path for the functions
% necessary for feature generation. FilterBank.mat is used to specify which
% spatial derivatives are to be taken. 
TempPath = max(strfind(FilePath,'\'));
TempPath = FilePath(1:TempPath-1);
cd(strcat(TempPath ,'\Feature Generation'))
load('FilterBank.mat');
addpath(pwd)

% Load trained svm which eliminates spurious false positive objects:
cd(strcat(FilePath,'\Classify TP and FP objects'))
load(TP_FP_ClassifierName)

% Go to folder containing the subfolders with image stacks:
Startpath = FilePath;
ImPath=uigetdir(Startpath, 'Chose the folder with the images');
cd(ImPath);   % legt ImPath als aktuellen folder fest
FolderList = dir();

% Remove non-directory entries and folders containing the word
% "classification":
count = 0;
Idx = [];
for i = 1:length(FolderList)
    if FolderList(i).isdir == 0 | strfind(FolderList(i).name,'Classification')
        count = count+1;
        Idx(count) = i;
    end
end
FolderList(Idx) = [];

% Go through all folders and perform the analysis:
for FolderNum = 3:length(FolderList)

    % Get most frequent image associated file extension:
    [extension] = GetExtension(strcat(ImPath,'\',FolderList(FolderNum).name));
    % Get the filenames:
    FileNamesTif  = dir(fullfile(FolderList(FolderNum).name, sprintf('*%s',extension)));
    FileNamesTif = {FileNamesTif.name};
    m = numel(FileNamesTif);
    bilder=[];    
    
    % Go to subfolder with the images:
    cd(FolderList(FolderNum).name); 
    % Read all files.
    stack = [];
    count = 1;
    for k=1:m
        % Filename
        d = FileNamesTif{k};
        % Get the file
        f = fullfile(FolderList(FolderNum).name , d);
        bilder = imread(f);
        % If image is rgb transform to grayscale:
        if size(bilder,3) == 3
            bilder=rgb2gray(bilder);
        end
        % If image is uint16 or uint32 transform it to uint8:
        if isa(bilder,'uint8')
            stack(:,:,count)=bilder;
        elseif isa(bilder,'uint16') || isa(bilder,'uint32')
            stack(:,:,count)=im2uint8(bilder);
        end
        clear bilder
        count  = count + 1;
    end    
    % Rescale input image:
    NormedStack = (double(stack)-min(stack(:))) ./ (max(stack(:))-min(stack(:)));
     
    % Generate feature space:
    Features = GenFeatures(NormedStack,sigma,FiltDirGD,FiltLG,TopHatSizes,EntropySizes); 
    % Reshape "Features" to 2d array:
    Features = reshape(Features, size(Features,1)*size(Features,2),size(Features,3));
    % Transform feature space using PCA coefficients:
    FeaturesRed = Features*CoeffAll;
    % Generate reduced data set:
    FeaturesRed = FeaturesRed(:,1:NumParamAll);       
    % Predict labels:
    LabelsPred = double(MLPModel.predict(FeaturesRed))';

    % Get positive labels:
    Idx = find(LabelsPred == 1);     
    % Get pixels with low intensity that are highly likely no positive
    % signals:
    % Filter input image and rescale it:
    TempIm = max(imgaussfilt3(stack,3,'Filtersize',[5 5 3]),[],3);
    TempIm = (TempIm -min(TempIm(:))) ./ (max(TempIm(:))-min(TempIm(:)));
    % Minimal relative Intensity for a pixel to be considered positive:
    MinInt = 0.10;
    % Indices of too dim pixels to be considered positive signals:
    IdxLowInt = NormedStackProj<MinInt*max(TempIm(:));
    IdxLowInt = find(IdxLowInt);
    % Check for overlap between too dim pixels and those classified as true
    % positive signals by the model:
    Overlap = ismember(Idx,IdxLowInt);
    % Remove too dim pixels from the positive signals:
    Idx(Overlap) = [];
    
    % Go back to image folder:
    cd(ImPath);    
       
    % Generate binary image of positive signals:
    Binary = false(size(NormedStackProj));
    Binary(Idx) = true;
    % Remove spurious(too small) objects:
    MinArea = 30; % Initially:10
    Binary = bwareaopen(Binary,MinArea);
    % morphological opening:
    se = strel('disk',1);
    Binary = imopen(Binary,se);
    Binary = bwareaopen(Binary,MinArea);
    % figure; imshow(Binary)
     
    % Gives the folder name for saving all images. This folder can be 
    % found in the folder were the analyzed images are contained in the
    % following subfolder:
    folder = fullfile(strcat(ImPath,'\','Classification_',ModelName));       
    % Checks the existence of the folder with the name "Results". If it
    % does not exist it is created.
    if (exist(folder) == 0)        
        mkdir(strcat('Classification_',ModelName));           
    end    
    cd(folder)     
   
    % Remove false positive objects:
    % List of positive signals:
    IDXList = regionprops('table',Binary,'PixelIdxList');
    % List of object properties:
    statsTemp = regionprops('table',Binary,'Area','ConvexArea','Eccentricity','EquivDiameter','Extent','MajorAxisLength','MinorAxisLength','Perimeter','Solidity');
    statsTemp.Circularity = 4*pi*statsTemp.Area./(statsTemp.Perimeter.^2);
    % Identify true and false positive objects using the trained model:
    [label,score] = predict(SVMModel,table2array(statsTemp));
    FPIdx = find(label == 2);
    TPIdx = find(label == 1);
    % Make binar of true positives only:
    TP = false(size(Binary));    
    for i = 1:size(TPIdx,1)
        TP(IDXList.PixelIdxList{TPIdx(i)}) = 1;
    end
    
    % Split objects in predicted image (Hough transformation) and save
    % overall number of PI positive cells:    
    % Get foci for manual/human markings:
    [centers_h, radii] = imfindcircles(TP,[1,40],'Method','TwoStage','Sensitivity',0.93);
    % remove to big objects:
    idx = find(radii > 20);
    centers_h(idx,:) = [];
    radii(idx) = [];
    save('NumberPIPositives.mat',length(radii))    
    
    % Generate resulting image:
    red = NormedStackProj;
    green = TP.*NormedStackProj;
    RGB(:,:,1) = red;
    RGB(:,:,2) = green;
    RGB(:,:,3) = zeros(size(red));
    % Save image:
    SaveVar = sprintf('%s %s Overlay',FolderList(FolderNum).name, ModelName);
    figure('units','normalized','outerposition',[0 0 1 1]);
    imshow(RGB,[])    
    saveas(gcf,sprintf('%s.png',SaveVar))
    savefig(gcf,sprintf('%s.fig',SaveVar))
    close all
    % Save regionprops:
    stats = regionprops('table',TP,'Area','ConvexArea','Eccentricity','EquivDiameter','Extent','MajorAxisLength','MinorAxisLength','Perimeter','PixelIdxList','Solidity');
    BinaryPredicted = TP; 
    cd ..
    cd(FolderList(FolderNum).name); 
    save(sprintf('StatsData %s.mat',ModelName),'stats','BinaryPredicted');
    cd ..    
end