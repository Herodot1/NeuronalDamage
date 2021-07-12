% Generate data to compare the actually predicted positive signals with the
% training TP and TN signals to identify those signals with significant
% overlap between both groups to split the predicted labels into TP and FP
% to train a machine learning algorithm into differentiating between both:

% Needs to be pointed to the OHSC images already classified by the
% "ApplyModel.m" file, as it needs the file named 'sprintf('StatsData %s.mat',ModelName)'


clear all;
%% Parameter:
% Name of the used model in the "ApplyModel.m" file used for generating the
% "StatsData" File, e.g. sprintf('StatsData %s.mat',ModelName) 
DataFileName =  sprintf('StatsData %s.mat','FinalModel MLP All pca99.9%.p');
%%

% Get path of m-file:
FilePath = fileparts(mfilename('fullpath'));
StartDir = addpath(pwd);  % Adds the path where the m-files are stored in
Startpath='E:\CellObserver';
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

% Save current directory:
CurrDir = pwd;
% Allocate variables:
% Assign empty tables:
statsTP = table('Size',[0 10], 'VariableTypes',{'double','double',...
    'double','double','double','double','double','double','double',...
    'double'},'VariableNames',{'Area','MajorAxisLength',...
    'MinorAxisLength','Eccentricity','ConvexArea','EquivDiameter',...
    'Solidity','Extent','Perimeter','Circularity'});
statsFP = table('Size',[0 10], 'VariableTypes',{'double','double',...
    'double','double','double','double','double','double','double',...
    'double'},'VariableNames',{'Area','MajorAxisLength',...
    'MinorAxisLength','Eccentricity','ConvexArea','EquivDiameter',...
    'Solidity','Extent','Perimeter','Circularity'});
% go through all folders and load the TN and TP data, if it exists:
for FolderNum = 3:length(FolderList)
    % Get m-files only:
    extension = '.mat';
    FileNames  = dir(fullfile(FolderList(FolderNum).name, sprintf('*%s',extension)));
    FileNames = {FileNames.name};
    % Go to subfolder:
    cd(FolderList(FolderNum).name);     
    % Check if traning files exist and if so load them:
    if any(strcmp(FileNames,'Training TN.mat'))
        load('Training TN.mat')
        BinaryTN = logical(BinaryTN);
     end    
    if any(strcmp(FileNames,'Training TP.mat'))
        load('Training TP.mat')
    end    
    % Check if StatsData exists:
    if any(strcmp(FileNames,DataFileName))
       load(DataFileName) 
    else
        fprintf('Warning. "%s" File not found in folder "%s". \n',DataFileName,FolderList(FolderNum).name)
    end
    
    % Check which objects in StatsData have overlap with the TP or TN data:
    
    % FP identification:
    % Remove predicted objects not in TN:
    OverlapFP = BinaryTN & BinaryPredicted;
    % Find centers in OverlapFP that are most closely to the ones in
    % BinaryPredicted, as these are likely the FP data points:
    CentersPredictedTN = regionprops('table',BinaryPredicted,'Centroid','PixelIdxList');
    CentersOverlapFP = regionprops('table',OverlapFP,'Centroid');    
    Val = NaN(size(CentersOverlapFP));
    Idx = Val;
    for i = 1:size(CentersOverlapFP,1)        
        Dist = ((CentersOverlapFP.Centroid(i,1)-CentersPredictedTN.Centroid(:,1)).^2 + (CentersOverlapFP.Centroid(i,2)-CentersPredictedTN.Centroid(:,2)).^2).^(0.5);
        [Val(i),Idx(i)] = min(Dist);            
    end
    % Remove Spurious stuff:
    Idx(Val>10) = [];    
    % Create final FP image:    
    FP = false(size(BinaryTN));
    if ~isempty(Idx)
        for i = 1:size(Idx,1)
            FP(CentersPredictedTN.PixelIdxList{Idx(i)}) = 1;
        end
    end  
    
    % TP identification:
    % Remove predicted objects not in TP:
    OverlapTP = BinaryTP & BinaryPredicted;    
    % Find centers in OverlapTP that are most closely to the ones in
    % BinaryPredicted, as these are likely the TP data points:
    CentersPredictedTP = regionprops('table',BinaryPredicted,'Centroid','PixelIdxList');
    CentersOverlapTP = regionprops('table',OverlapTP,'Centroid');    
    Val = NaN(size(CentersOverlapTP));
    Idx = Val;
    for i = 1:size(CentersOverlapTP,1)        
        Dist = ((CentersOverlapTP.Centroid(i,1)-CentersPredictedTP.Centroid(:,1)).^2 + (CentersOverlapTP.Centroid(i,2)-CentersPredictedTP.Centroid(:,2)).^2).^(0.5);
        [Val(i),Idx(i)] = min(Dist);            
    end
    % Remove Spurious stuff:
    Idx(Val>10) = [];    
    % Create final TP image:    
    TP = false(size(BinaryTP));
    if ~isempty(Idx)
        for i = 1:size(Idx,1)
            TP(CentersPredictedTP.PixelIdxList{Idx(i)}) = 1;
        end
    end
    
    % Lastly, check if objects are uesd in both and remove them:
    OverlapFPTP = TP & FP;
    % Remove overlapping regions:
    TP = TP & ~OverlapFPTP;
    FP = FP & ~OverlapFPTP;     
    % Get object TP properties:
    statsTPTemp = regionprops('table',TP,'Area','ConvexArea','Eccentricity','EquivDiameter','Extent','MajorAxisLength','MinorAxisLength','Perimeter','Solidity');
    statsTPTemp.Circularity = 4*pi*statsTPTemp.Area./(statsTPTemp.Perimeter.^2);
    % Get FP object properties:
    statsFPTemp = regionprops('table',FP,'Area','ConvexArea','Eccentricity','EquivDiameter','Extent','MajorAxisLength','MinorAxisLength','Perimeter','Solidity');
    statsFPTemp.Circularity = 4*pi*statsFPTemp.Area./(statsFPTemp.Perimeter.^2);
    
    % Append data to final stats list:
    statsTP(end+1:end+size(statsTPTemp,1),:) = statsTPTemp;
    statsFP(end+1:end+size(statsFPTemp,1),:) = statsFPTemp;
    % Go back to initial folder:
    cd(CurrDir);     
    
    % Removes unnecessary variables:
    clear BinaryTN BinaryTP BinaryPredicted  TNList TPList FP TP stats
end
% Go to the folder this file is located and save the morphological data:
cd(FilePath)
save(sprintf('TP_FP_Data.mat'),'statsTP','statsFP')




