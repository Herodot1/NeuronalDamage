% Get training data for true positives:
% Use manual input via point and click. everything around point is positive
% or negative (determine dot-size manually -> first estimate: max 9px
% diameter)
% Keys/etc associated with the manual point-and-click-interface:
% left arrow = zoom out
% right arrow = zoom in
% backspace = remove last point
% left mouse click = add point

clear all;

% Get path of m-file:
FilePath = fileparts(mfilename('fullpath'));
addpath(FilePath);  % Adds the path where the m-files are stored in
addpath(strcat(FilePath,'\HelperFunctions'))

% Save name for resulting file. If changed, other m-files reffering to this
% need adjustments.
SaveName = 'Training TP';

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

% Get points of interest:
RedIm = zeros(size(ProjIm,1),size(ProjIm,2),3);
RedIm(:,:,1) = ProjIm;

% use optimized ginput to mark user define points:
figure;
imshow(RedIm, [])
X = []; Y = [];
hold on
CurrPlot = plot(X, Y, 'og');
% Buttons correspond to left or right arrow
while true
    [x,y,button] = MyGinput(1,[234, 137, 154]/255); 
    if isempty(button)
        break;
    elseif button==28 % left arrow, zoom out
        ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
        axis([x-width/2 x+width/2 y-height/2 y+height/2]);
        zoom(1/2);
    elseif button==29 % right arrow, zoom in
        ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
        axis([x-width/2 x+width/2 y-height/2 y+height/2]);
        zoom(2);    
    elseif button==8 % backspace, remove last point
        X(end) = [];
        Y(end) =[];
        delete(CurrPlot) % Delete data of old plot
        hold on
        CurrPlot = plot(X, Y, 'og');
        drawnow
    elseif button==1 % left mouse click, add point
        X=[X;x];
        Y=[Y;y];
        % delete data of old plot. if it is not done it will generate 
        % multiple plot with only the last being called "CurrPlot" and 
        % thus not being deletable
        delete(CurrPlot)
        hold on
        CurrPlot = plot(X, Y, 'og');
        drawnow
    end    
end
close all

% use extended h-max transform to get regional maxima, that also contain
% the PI positive nuclei (and diverse type of junk). 
MaxIm1 = imextendedmax(ProjIm,0.05);
% Make small dots more prominent:
MaxIm1 = imdilate(MaxIm1,strel('disk',2));
MaxIm1 = bwareaopen(MaxIm1,10);
% Check which points correspond with maxima, as these are highly likely PI
% positve cells:
stats = regionprops(MaxIm1,'ConvexHull','PixelIdxList');
count = 0;
for i = 1:length(stats)
    xv = stats(i).ConvexHull(:,1);
    yv = stats(i).ConvexHull(:,2);
    in = inpolygon(X,Y,xv,yv);
    if sum(find(in == 1)) > 0
        count = count+1;
        ID(count:count + numel(find(in == 1)) - 1,1) = find(in == 1);
        ID(count:count + numel(find(in == 1)) - 1,2) = i;
        count = count - 1 + numel(find(in == 1));
    end
end
StatsTP = stats(unique(ID(:,2)));
BinaryTP = false(size(ProjIm));
TPList = [];
for i = 1:length(StatsTP)
    BinaryTP(StatsTP(i).PixelIdxList(:)) = 1;
    TPList(length(TPList)+1:length(TPList)+length(StatsTP(i).PixelIdxList(:))) = StatsTP(i).PixelIdxList(:);
end

% Make a merged image containing h-max transformation and original image:
% red = ProjIm;
% green = MaxIm1.*ProjIm;
% RGB(:,:,1) = red;
% RGB(:,:,2) = green;
% RGB(:,:,3) = zeros(size(red));
% for i = 1:length(X)
%     RGB(round(Y(i)-2:Y(i)+2),round(X(i)-2:X(i)+2),3) = 1;
% end
% figure; imshow(RGB)
save(sprintf('%s.mat',SaveName),'X','Y','StatsTP','BinaryTP','TPList')




