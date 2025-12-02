%% Model comparison for AET Models
% This script compares models fit using the fitAET script, using metrics
% including BIC, AIC, psuedo-R2 and (protected) exceedance probabilities
%
% based on code from Todd Vogel 2024 for PAR task 
%
% Emma Scholey
% Date: 19/11/2025

%% Set up ------------------------------------------------------------------
clearvars; close all

study_version = 'v3'; % which version of data to look at (v1, v3, mri)
fit_flag = 0;

model_ids = [2,3,5,6]; 

%model_ids = [3,8]; % weight tau vs no tau - no tau is better
%model_ids = [1,3,5]; % no tau - weight vs additive vs original - weight is better


%% Load model outputs -----------------------------------------------------
config = config_study(study_version, fit_flag);

fitted_models = cell(1,length(model_ids));

% Generate model IDs from 101 to 121
model_ids = arrayfun(@(x) sprintf('M%d', x), model_ids, 'UniformOutput', false);

for imodel = 1:length(model_ids)
    load([config.paths.data_fit, 'fitting_hierarchical_' model_ids{imodel}]);
    fitted_models{imodel} = modout;
    
end
fitted_models = cell2struct(fitted_models, model_ids, 2);

%% Compare models ------------------------------------------------------------------
EMmc_ms(fitted_models, model_ids); % function to plot comparisons based on log model evidence, BIC, and exceedance probabilities

% Calculate R^2 & extract model fit measures
lme_all = nan(modout.nsubj, numel(model_ids));
fits    = nan(numel(model_ids), 5);
for imodel = 1:numel(model_ids) % for the number of models
    model_id      = model_ids{imodel};
    nll           = fitted_models.(model_id).nll;
    nsubj         = fitted_models.(model_id).nsubj;
    ntrials       = fitted_models.(model_id).ntrials;
    fitted_params = fitted_models.(model_id).fitted_params_real;
    lme_all(:, imodel) = fitted_models.(model_id).lme;
    fitted_models.(model_id).pseudoR2 = pseudoR2(nll, config.task);

    fits(imodel, 1) = sum(fitted_models.(model_id).lme);
    fits(imodel, 2) = fitted_models.(model_id).bicint;
    fits(imodel, 3) = fitted_models.(model_id).pseudoR2;
    fits(imodel, 4) = fitted_models.(model_id).choiceprob_median_R2;
end
[~, ~, xp_all, pxp_all] = spm_BMS(lme_all); % log model evidence % FIXME: make version that doesn't rely on SPM (maybe? https://github.com/sjgershm/mfit/blob/master/bms.m)
fits(:, 5) = xp_all;
fits(:, 6) = pxp_all;
fits_table = array2table(fits, "VariableNames", ["lme", "bicint", "pseudoR2", "choice_prob_median_R2", "xp", "pxp"]);
fits_table = addvars(fits_table, model_ids(:),'Before', 1, 'NewVariableNames', "model_id");

