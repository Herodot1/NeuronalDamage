% Do model training using the full data set and save the trained model.

clear all

%% Input parameters:
% Amount of variance captured by PCA components in per cent:
PercExpl = 99.9;
% Parameters for setting up the python environement:
% Path to the conda installation, e.g.'C:\ProgramData\anaconda3'
CondaPath = 'C:\ProgramData\anaconda3';
% Name of the conda environement to be used, e.g. 'root'
EnvName = 'UseFromMatlab';
% Name of a specified module to be load, e.g. 'sklearn'
ModuleName = 'sklearn';
% Name of the .mat file containing the training features. Needs to be in
% the same folder as this file
TrainFeatName = 'TrainingFeatures 06-01-2021.mat';

%%
% Add python environment:
AddCondaEnvironementToMatlabPath(CondaPath,EnvName,ModuleName)

CurrDir = pwd;
addpath(pwd)
% First load traning data sets:
load(TrainFeatName)
cd(CurrDir)
  
% Get MLP model from python:
MLPModel = py.sklearn.neural_network.MLPClassifier(pyargs('alpha',0.1,...
    'batch_size',int32(5000),'learning_rate','adaptive','learning_rate_init',0.1,...
    'max_iter',int32(300),'tol',10^-4,'early_stopping',true(1)));

% Aggregate Features:
FeaturesAll = [];
%true positives:
for i = 1:size(TPFeatures,1)
    Tmp = TPFeatures{i};
    FeaturesAll(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;    
end
Labels = ones(size(FeaturesAll,1),1);
%true negatives:
for i = 1:size(TNFeatures,1)    
    Tmp = TNFeatures{i};
    FeaturesAll(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;    
end
Labels(end+1:size(FeaturesAll,1)) = 2;

% Use PCA to reduce feature space - using the whole data set:
[CoeffAll, Score, Latent, TSquared, Explained] = pca(FeaturesAll);
% Find 99% of variance point:
ExpSum = cumsum(Explained);
NumParamAll = find(ExpSum>PercExpl,1);
% Generate reduced data set:
DataTrainAll = FeaturesAll*CoeffAll;
DataTrainAll = DataTrainAll(:,1:NumParamAll);

% Train MLP classifier on data set using all data on TP and TN
% Use all data for TP and TN:
MLPModelAll = MLPModel.fit(DataTrainAll,Labels);

% Save model and PCA coefficients:
str = sprintf('FinalModel MLP All pca%2.1f%%.p',PercExpl);
file = py.open(str,"wb");
py.pickle.dumb(MLPModel,file);
file.close()

save(sprintf('Scalings FinalModel MLP All pca%2.1f%%.mat',PercExpl),'CoeffAll','NumParamAll')


    