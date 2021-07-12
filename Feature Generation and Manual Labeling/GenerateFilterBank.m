% Create Filter bank for feature generation:

%% Parameters:
% Derivatives and directions used for the gaussian derivative Filter:
FiltDirGD = [[1,0,0]; [2,0,0]; [0,1,0]; [0,2,0]; [0,0,1]; ...
    [0,0,2]; [1,1,0]; [2,2,0]; [1,1,1]; [2,2,2]];% ordering: y,x,z dimension
% Parameters for Laguerre Gaussian polynomials:
% meshgrid size and spacing
Sz = 5;
StepSz = 1;
% maximal parameters for Laguerre Gaussian polynomials (need to be integers)
% additional, currently fixed parameters are defined further below.
lmax = 2;
pmax = 2;

%%
% Get path of m-file:
FilePath = fileparts(mfilename('fullpath'));
addpath(FilePath);  % Adds the path where the m-files are stored in
addpath(strcat(FilePath,'\HelperFunctions'))

% Gaussian derivative filter:
FiltGD = {};
count = 0;
NormedStack = ones(100,100,30);
for sigma = 1:6
    for i = 1:size(FiltDirGD,1)
        % Direction of orders: [y,x,z]
        count = count+1;
        [tmp,filttmp] = gfilter(NormedStack,sigma,FiltDirGD(i,:));
        FiltGD{count} = filttmp;
    end
end

% Add laguerre gaussian filters; notation: laguerreL(p,l,x)
[X,Y] = meshgrid(-Sz:StepSz:Sz,-Sz:StepSz :Sz);
[thetamesh,rmesh] = cart2pol(X,Y);
s = 0.5;
q = 2;
r = 0.0;
count = 0;
for p = 0:pmax
    for l = 0:lmax
        count = count + 1;
        LG = zeros(size(thetamesh));
        TempVar1 = cos(l*( (thetamesh + 2*r*pi./max([2*l,1]) ) ) );
        TempVar2 = laguerreL(p,l,rmesh*s.*atan(rmesh*s));
        TempVar3 = (exp(-(rmesh*s).^(2/q))) .* ((rmesh*s).^(l/q));
        TempVar4 = TempVar3 .* ((TempVar1.*TempVar2).^(3-q));
        LG = LG + TempVar4;  
        FiltLG{count} = LG;
    end
end

% Save the filters:
save('FilterBank.mat','FiltDirGD','FiltGD','FiltLG')
