function fits_table = EMmc_ms(fitted_models, model_ids,config, fit_type)
%function EMmc_ms(fitted_models, model_ids)
% Compares models using LME, BICint, and exceedance probabilities
% MK Wittmann, Nov 2017
% Edited by Todd Vogel, 2024
%
% Dependencies:
%   Currently requires SPM to do bayesian model comparison using spm_BMS
%   Possible to do without SPM? (see https://github.com/sjgershm/mfit/blob/master/bms.m)

arguments
    fitted_models {mustBeA(fitted_models, 'struct')} 
    model_ids (1, :) {mustBeA(model_ids, 'cell')}
    config
    fit_type
end

xtickrot = 25;

% Get model info
for imodel = 1:numel(model_ids)
    model_id = model_ids{imodel};

    switch fit_type
        case 'MAP'
            lme_all(:, imodel) = fitted_models.(model_id).lme; % log model evidence
            bic_all(imodel) = fitted_models.(model_id).bicint;
        case 'MLE'
            bic_all(imodel) = sum(fitted_models.(model_id).bic);
            lme_all(:,imodel) = fitted_models.(model_id).bic;  % no log model evidence for MLE - approximate with BIC to compute posterior probabilities later
    end
end

% I. Plot LME and BIC: --------------------------------------------------
% 1) LME sum
h = figure('name', "AET");
sgtitle('Bayesian Model Comparison');
tiledlayout("flow");

% nexttile;
% bar(sum(lme_all)); 
% set(gca, 'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot); 
% ylabel('Summed log evidence (more is better)', 'FontWeight', 'bold');

% 2) BICint
nexttile;
bar(bic_all - min(bic_all)); %TV: added in to compare models against best fitting instead of raw BIC numbers
set(gca, 'XTick', 1:numel(model_ids), 'XTickLabel', model_ids);
set(gca, 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
ylabel('Δ BIC from lowest', 'FontWeight', 'bold'); %TV: adjusted label to reflect comparison to best BIC 

% II Calculate exceedence probabilities ----
% this is coming from SPM you need to have it somewhere in your paths

switch fit_type
    case 'MAP'
        [~, ~, xp, pxp] = spm_BMS(lme_all);
    case 'MLE'
        posteriorProbabilities = BICposterior(lme_all); % approximate log model evidence using Wagenmakers equation
        [~, ~, xp, pxp] = spm_BMS(posteriorProbabilities);
end

nexttile;
bar(xp);
set(gca,'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
rl1 = yline(0.8);     
ylim([0,1])
set(rl1, 'linestyle', '--', 'Color', 'r');
ylabel('Exceedence Probability', 'FontWeight', 'bold');

% Calculate protected exceedance probabilities
nexttile;
bar(pxp);
set(gca,'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
rl1 = yline(0.8);     
ylim([0,1])
set(rl1, 'linestyle', '--', 'Color', 'r');
ylabel('Protexted XP', 'FontWeight', 'bold');

% Calculate R^2 & extract model fit measures
fits    = nan(numel(model_ids), 5);
for imodel = 1:numel(model_ids) % for the number of models
    model_id      = model_ids{imodel};
    nll           = fitted_models.(model_id).nll;
    nsubj         = fitted_models.(model_id).nsubj;
    ntrials       = fitted_models.(model_id).ntrials;
    fitted_params = fitted_models.(model_id).fitted_params_real;

    fitted_models.(model_id).pseudoR2 = pseudoR2(nll, config.task);

    switch fit_type
        case 'MAP'
            fits(imodel, 1) = fitted_models.(model_id).bicint; % sum BIC
        case 'MLE'
            fits(imodel, 1) = sum(fitted_models.(model_id).bic); % % sum BIC - not integrated
    end

    fits(imodel, 2) = fitted_models.(model_id).pseudoR2;
    fits(imodel, 3) = fitted_models.(model_id).choiceprob_median_R2;
end
fits(:, 4) = xp;
fits(:, 5) = pxp;
fits_table = array2table(fits, "VariableNames", ["bic", "pseudoR2", "choice_prob_median_R2", "xp", "pxp"]);
fits_table = addvars(fits_table, model_ids(:),'Before', 1, 'NewVariableNames', "model_id");

