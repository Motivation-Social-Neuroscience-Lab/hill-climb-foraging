function [choiceprob_medianR2, choiceprob_meanR2] = choiceProbR2(fitted_params_real, task, model, behav_data)
%function [choiceprob_medianR2, choiceprob_meanR2] = choiceProbR2(fitted_params, model_id, behav_data)
%
% DESCRIPTION:
%   Function to calculate R squared of a model based on the choice probabilities,
%   calculated using either the median or mean.
%
% AUTHORS:
%   Jo Cutler April 2020
%   edited by Todd Vogel 2024
%   edited by Emma Scholey 2025 for AET 

arguments
    fitted_params_real (:, :) {mustBeNumeric} % nparams (rows) x nsubj (cols) array of fitted parameters in model space
    task struct                               % task options
    model struct                              % model options
    behav_data (1, :) {mustBeA(behav_data, 'cell')} % 1 x nsubj cell array of all subjects data 
end

%%
nsubj = numel(behav_data);

% Get choice probabilities (from fitted parameters) for each participant
choiceprobs_median = zeros(1, nsubj);
choiceprobs_mean   = zeros(1, nsubj);

for isubj = 1:nsubj

    agent = behav_data{isubj};
    [~, out] = simulate_AET_model(task, model, agent, fitted_params_real(:, isubj)'); 

    choiceprobs_median(isubj) = median(out.pSelected);
    choiceprobs_mean(isubj)   = mean(out.pSelected);
end

% Calculate median and mean R^2 for the model
choiceprob_medianR2 = median(choiceprobs_median)^2;
choiceprob_meanR2   = mean(choiceprobs_mean)^2;