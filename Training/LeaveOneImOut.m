% Do model training using a "leave one image out" strategy for testing, to 
% check stability of the found solution. It needs the .mat file with the
% training features to be in the same folder as this file. 
% This script trains the MLP model using all but one OHSC and testing the
% model on the remaining one, for all possible combinations. 
% Output: 'LeaveOneOutData + ModelName.mat', containing the number of true
% and false positives and true and false negatives. 

clear all

%% Input parameters:
% Amount of variance captured by PCA components in per cent:
PercExpl = 99.9;
% Model name used for saving the data:
ModelName = 'MLP 99.9% PCA';
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

% Aggregate features, leaving one image out:
for LeaveOneOut = 1:size(TNFeatures,1)
    LeaveOneOut
    % Aggregate Features:
    FeaturesAll = [];
    FeaturesTest = [];
    
    %true positives:
    for i = 1:size(TPFeatures,1)
        if LeaveOneOut ~= i
            Tmp = TPFeatures{i};
            FeaturesAll(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;
        else
            Tmp = TPFeatures{i};
            FeaturesTest(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;
        end
    end
    Labels = ones(size(FeaturesAll,1),1);
    LabelsTest = ones(size(FeaturesTest,1),1);
    
    %true negatives:
    for i = 1:size(TNFeatures,1)
        if LeaveOneOut ~= i
            Tmp = TNFeatures{i};
            FeaturesAll(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;
        else
            Tmp = TNFeatures{i};
            FeaturesTest(end+1:end+size(Tmp,1),1:size(Tmp,2)) = Tmp;
        end
    end
    Labels(end+1:size(FeaturesAll,1)) = 2;
    LabelsTest(end+1:size(FeaturesTest,1)) = 2;
    
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
    % Set up test data
    DataTest = FeaturesTest*CoeffAll;
    DataTest = DataTest(:,1:NumParamAll);
    % Predict labels of test data:
    LabelsPred = double(MLPModelAll.predict(DataTest))';

    % Calculate confusion matrix:
    [C,~] = confusionmat(LabelsTest,LabelsPred);
    % TP/TN/FP/FN:
    if size(C,1) == 1
        TPAll(LeaveOneOut) = C(1,1);
        TNAll(LeaveOneOut) = 0;
        FNAll(LeaveOneOut) = 0;
        FPAll(LeaveOneOut) = 0;
    else
        TPAll(LeaveOneOut) = C(1,1);
        TNAll(LeaveOneOut) = C(2,2);
        FNAll(LeaveOneOut) = C(1,2);
        FPAll(LeaveOneOut) = C(2,1);
    end
    % Save data:
    save(strcat('LeaveOneOutData',ModelName,'.mat'),'TPAll','FPAll','TNAll','FNAll')
    
end
% Accuracy:
Accuracy = (TPAll+TNAll)./(TPAll+FPAll+FNAll+TNAll);
% MCC - Mathews correlation coefficient:
Denom = (TPAll.*TNAll) - (FPAll.*FNAll);
Enume = ( (TPAll+FPAll) .* (TPAll+FNAll) .* (TNAll+FPAll) .* (TNAll+FNAll) ).^(0.5);
MCC = Denom./Enume;