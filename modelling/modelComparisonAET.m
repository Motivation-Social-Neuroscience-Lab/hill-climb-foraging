%% model comparison of AET
% Emma Scholey, 5 June 2023
clearvars; close all

addpath('../../figures/functions/')
addpath('./helperFunctions/')

run figure_properties_aet.m

%modelTable = readtable('./AETModelTable_final.xlsx');
modelTable = readtable('./AETModelTable_new.xlsx');

dataVersion = 'mri'; % which version of data to look at (v1, v3, mri)

%modelNum = [1,5,6,13,14,18];

modelNum = [103, 104, 106:109];
modelNum = [106,107];
modelNum = [107, 110];
%modelNum = [103,104,106];
%modelNum = [1,3,5:7];
%modelNames = {'1\kappa 1\beta', '1\kappa 2\beta','\tau 1\kappa 1\beta', '\tau 2\kappa 1\beta', '\tau 1\kappa 2\beta'};
%modelNames= [1:12];
%% AIC/BIC
fontsize = 20;
nModels = numel(modelNum);

models_AIC = zeros([nModels 1]);
models_BIC = zeros([nModels 1]);

for iM = 1:nModels
    %load(sprintf('../../data_derived/%s/fitting/fitting_M%d', dataVersion, modelNum(iM)));
    load(sprintf('./data_derived/%s/fitting_hierarchical/fitting_hierarchical_M%d', dataVersion, modelNum(iM)));

    % ppts_AIC(:,iM) = AIC;
    % ppts_BIC(:,iM) = BIC;
    % models_AIC(iM) = sum(AIC);
    % models_BIC(iM) = sum(BIC);
    ppts_BIC(:,iM) = modout.bic;
    models_BIC(iM) = sum(modout.bic);
end

%ppts_BIC = ppts_BIC([1:5,7:23, 25:34, 36:end],:);
%models_BIC = sum(ppts_BIC);

% plot
minBIC = min(models_BIC);
bestModelNum = modelNum(models_BIC == minBIC);
bestModelIndex = find(bestModelNum == modelNum);
figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.horizontal);
h = bar(1:numel(modelNum), models_BIC); hold on
ylabel('Sum BIC')
h(1).FaceColor = colour.model;
h(1).EdgeColor = colour.model;

ylim([min(models_BIC)-25, max(models_BIC)+25])
% switch dataVersion
%     case 'v1'
%         ylim([4000, inf])
%     case 'v3'
%         ylim([4000, inf])
%     case 'mri'
%         ylim([4000, inf])
% end

set(gca, 'XTickLabel', modelNum, 'XTick', 1:numel(modelNum), 'XTickLabelRotation', 50)

%xticklabels(modelNames)

bar(bestModelIndex,minBIC, 'FaceColor',colour.model_highlight, 'EdgeColor', colour.model_highlight)

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
%print(['../../figures/panels/BIC_', dataVersion],'-dsvg')


% find best model for each participant
%
subjectBestModelBIC = ppts_BIC == min(ppts_BIC, [], 2);
numBestModelBIC = sum(subjectBestModelBIC);

% save fit params for winning model for further analysis
%load(sprintf('../../data_derived/%s/fitting/fitting_M5', dataVersion));
%writetable(minNLLFitParams,sprintf('../../data_derived/%s/fitting/minNLLFitParams_M5.csv', dataVersion));

%% AIC

% figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.horizontal);
% h = bar(1:numel(modelNum), models_AIC, 'FaceColor',colour.model, 'EdgeColor', colour.model); hold on
% ylabel('Sum AIC')


%% Number of participants best fit by each model

% show best model per participant
subjectBestModelBIC = ppts_BIC == min(ppts_BIC, [], 2);
sumBestModel = sum(subjectBestModelBIC);
bestModelIndex = find(sumBestModel == max(sumBestModel));

figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);

bar(1:nModels,sumBestModel,'FaceColor',colour.model, 'EdgeColor', colour.model), hold on
ylabel('Number of subjects')
%set(gca,'XTickLabel',modelNames, 'XTickLabelRotation',50)
bar(bestModelIndex,sumBestModel(bestModelIndex), 'FaceColor',colour.model_highlight, 'EdgeColor', colour.model_highlight)

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
%print(['../../figures/panels/BIC_per_subject_', dataVersion],'-dsvg')


%% exceedance probabilities

% 1. comparing only winning model vs null model
posteriorProbabilities = BICposterior(ppts_BIC);

% figure
% bar(sort(posteriorProbabilities(:,2)-posteriorProbabilities(:,1)), 'FaceColor',colour.model, 'EdgeColor', colour.model)
% ylabel(['p(model):', modelNames{bestModelIndex}, ' - null model'])
% 
% print(['../../figures/panels/posterior_p_win_model_vs_null_', dataVersion],'-dsvg')

% Compute exceedance probabilities (e.g., using SPM)
[~, ~, xp, pxp] = spm_BMS(posteriorProbabilities);

%% R-squared
% McFadden's Pseudo-R2, for binary outcomes
%L(fitted model): Log-likelihood of the model with the estimated parameters.
%L(null model): Log-likelihood of a null model (a model that predicts the mean response, i.e., no predictors).
% CALCULATE LL FOR NULL MODEL
% p(accept = 0.5) -> log(0.5)
funcOptions.type = 'simulate_new';
funcOptions.version = dataVersion;

task = buildTask(funcOptions);

clear minNLL

% how many choices does null model make, assuming 50% accept, 50% wait

nChoices = (task.blockTime*task.nBlocks)/mean([task.acceptTime, task.rejectTime] + 1); % total time/ mean time per trial (+1 is for the decision time point)
null_LL = (log(0.5)*nChoices);

R2 = zeros([1,nModels]);
mean_R2 = zeros([1,nModels]);
median_R2 = zeros([1,nModels]);

for iM = 1:nModels
    %load(sprintf('../../data_derived/%s/fitting/fitting_M%d', dataVersion, modelNum(iM)));
    load(sprintf('./data_derived/%s/fitting_hierarchical/fitting_hierarchical_M%d', dataVersion, modelNum(iM)));

    R2 = 1 - (-minNLL/null_LL); % create R2 for each person
    mean_R2(iM) = mean(R2);
    median_R2(iM) = median(R2);
end

% TO DO: put BIC, AIC, exceedance probabilities and R2 in one big dataframe
% and save as csv 
xp = xp'
pxp = pxp'
mean_R2 = mean_R2';
median_R2 = median_R2'; 
model_output = table(models_BIC, models_AIC, xp, pxp, mean_R2, median_R2);

%writetable(model_output, sprintf('../../data_derived/%s/fitting/fit_metrics', dataVersion));
