function EMmc_ms(fitted_models, model_ids)
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
end

xtickrot = 25;

% Get model info
for imodel = 1:numel(model_ids)
    model_id = model_ids{imodel};
    lme_all(:, imodel) = fitted_models.(model_id).lme; % log model evidence
    bicint_all(imodel) = fitted_models.(model_id).bicint;
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
bar(bicint_all - min(bicint_all)); %TV: added in to compare models against best fitting instead of raw BIC numbers
set(gca, 'XTick', 1:numel(model_ids), 'XTickLabel', model_ids);
set(gca, 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
ylabel('Δ BICint from lowest', 'FontWeight', 'bold'); %TV: adjusted label to reflect comparison to best BIC 

% II Calculate exceedence probabilities ----
% this is coming from SPM you need to have it somewhere in your paths
[~, ~, BMS.xp, BMS.pxp] = spm_BMS(lme_all);
nexttile;
bar(BMS.xp);
set(gca,'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
rl1 = yline(0.8);     
ylim([0,1])
set(rl1, 'linestyle', '--', 'Color', 'r');
ylabel('Exceedence Probability', 'FontWeight', 'bold');

% % Calculate protected exceedance probabilities
% nexttile;
% bar(BMS.pxp);
% set(gca,'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', xtickrot);
% rl1 = yline(0.8);     
% ylim([0,1])
% set(rl1, 'linestyle', '--', 'Color', 'r');
% ylabel('Protexted XP', 'FontWeight', 'bold');
