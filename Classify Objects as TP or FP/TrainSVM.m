% Train an SVM based on the object properties to identify false positive
% objects based on morphological features. It also performs a
% crossvalidation using 200 different splits to assess the goodness of the
% model.
% Needs the "TP_FP_Data.mat" file obtained using "GetTPandFP.m". 
% "TP_FP_Data.mat" needs to be in the same folder as this script. 
% Output file: sprintf('%s.mat',Modelname); Contains the trained SVM, as
% well as the number of true and false positives and true and false
% negatives obtained for each cross-validation step. 

clearvars -except statsTP statsFP;

%% Parameters:
% Save name for the model and associated data:
Modelname = 'Trained SVM MLP 99.9% PCA All Images';


%%
% load data:
load('TP_FP_Data.mat')
% Create labels and input data:
% TP data:
X = table2array(statsTP);
Labels = ones(size(X,1),1);
% FP data: 
X(end+1:end+size(statsFP,1),:) = table2array(statsFP);
Labels(end+1:end+size(statsFP,1)) = 2*ones(size(statsFP,1),1);

% Train SVM
tic
SVMModel = fitcsvm(X,Labels,'KernelFunction','rbf',...
    'Standardize',true,'OutlierFraction',0.05,'Cost',[0 1; 1.5 0]);%,'OptimizeHyperparameters','auto');
toc

% Crossvalidation error:
% SVM anonymus function:
classf = @(xtrain,ytrain,xtest,ytest) ...
    sum(ytest ~= predict(fitcsvm(xtrain,ytrain,'KernelFunction','rbf',...
    'Standardize',true,'OutlierFraction',0.05,'Cost',[0 1; 1.5 0]),xtest));

% Make cross validation to estimate the goodness of the model:
for i = 1:200    
    holdoutCVP = cvpartition(size(X,1),'holdout',0.3);
    TrainLabel = Labels(holdoutCVP.training);
    TrainData = X(holdoutCVP.training,:);
    TestLabel = Labels(holdoutCVP.test);
    TestData = X(holdoutCVP.test,:);
    
    SVMModel = fitcsvm(TrainData,TrainLabel,'KernelFunction','rbf',...
        'Standardize',true,'OutlierFraction',0.05,'Cost',[0 1; 1.50 0]);
    
    [PredictLabel,score] = predict(SVMModel,TestData);
    [C,~] = confusionmat(TestLabel,PredictLabel);
    % TP/TN/FP/FN:
    TP(i) = C(1,1);
    TN(i) = C(2,2);
    FN(i) = C(1,2);
    FP(i) = C(2,1);
end
toc

% Get precision/positive predictive value:
PPV = TP./(TP+FP);
% Get negative predictive value:
NPV = TN./(TN+FN);
% Get accuracy:
Acc = (TN+TP) ./ (TN+FN+TP+FP);
% Sensitivity:
Sens = TP ./(TP+FN);
% Specificity:
Spec = TN./(TN+FP);

% Save classification parameters and trained SVM:
save(sprintf('%s.mat',Modelname),'SVMModel','TP','TN','FP','FN')


