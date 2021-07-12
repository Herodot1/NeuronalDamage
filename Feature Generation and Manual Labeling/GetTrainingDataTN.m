% Get training data for true negatives:
% Use manual input via point and click. everything around point is positive
% or negative (determine dot-size manually -> first estimate: max 9px
% diameter)

clear all;
% Get path of m-file:
FilePath = fileparts(mfilename('fullpath'));
addpath(FilePath);  % Adds the path where the m-files are stored in
addpath(strcat(FilePath,'\HelperFunctions'))

% Save name for resulting file. If changed, other m-files reffering to this
% need adjustments.
SaveName = 'Training TN';

% Go to the folder containing the subfolders with images:
ImPath=uigetdir(Filepath, 'Chose the folder with the images');
cd(ImPath);   % legt ImPath als aktuellen folder fest
folderList = dir();
[extension] = GetExtension(ImPath);
filenames  = dir(fullfile(ImPath, sprintf('*%s',extension)));
filenames = {filenames.name};
m = numel(filenames);
bilder=[];

% Read all files.
stack = [];
tic
count = 1;
for k=1:m    
    % Filename
    d = filenames{k};
    % Get the file
    f = fullfile(ImPath , d);
    bilder = imread(f);
    if size(bilder,3) == 3
        bilder=rgb2gray(bilder);
    end
    if isa(bilder,'uint8')
        stack(:,:,count)=bilder;
    elseif isa(bilder,'uint16') || isa(bilder,'uint32')
        stack(:,:,count)=im2uint8(bilder);
    end    
    clear bilder
    count  = count + 1;
end
toc

% Maximal intensity projection:
ProjIm = max(imgaussfilt3(stack,3,'Filtersize',[5 5 3]),[],3);
% Rescale Image:
ProjIm = (ProjIm -min(ProjIm(:))) ./ (max(ProjIm(:))-min(ProjIm(:)));

% Mark whole regeions that are considered to only contain negative
% signals:
[BinaryTN] = DrawMultPolygons(RedIm);
close all
% Remove all pixels with to low intensity:
Idx = ProjIm>0.1*max(ProjIm(:));
BinaryTN = BinaryTN.*Idx;

StatsTN = regionprops(BinaryTN,'ConvexHull','PixelIdxList');
TNList = [];
for i = 1:length(StatsTN)
     TNList(length(TNList)+1:length(TNList)+length(StatsTN(i).PixelIdxList(:))) = StatsTN(i).PixelIdxList(:);
end
save(sprintf('%s.mat',SaveName),'StatsTN','BinaryTN', 'TNList')


