function [simdata, sim_fitted_params] = simulatedata(behav_data, fitted_params, model, task, nsim_subj, simulate_type)
% Simulate data based on modelID
% Written by Todd Vogel 2023
% edited Emma Scholey 19 November 2025 for AET

arguments
    behav_data (1, :) {mustBeA(behav_data, 'cell')} % 1 x nsubj cell array of all subjects data 
    fitted_params % nparam x nsubj array of fitted parameters
    model struct % model settings
    task struct % task settings
    nsim_subj % number of simulations to run
    simulate_type char
end

% Use real fitted values to generate simulated data
sim_fitted_params = min(fitted_params,[],2) + (max(fitted_params,[],2) - min(fitted_params,[],2)) .* rand(height(fitted_params), nsim_subj); %uniform distribution bounded by min/max of real data

% Simulate and fit X number of times
simdata = cell(1, nsim_subj);
for isub = 1:nsim_subj

    rand_subjnum = randi(numel(behav_data));
    agent.data = behav_data{rand_subjnum}.data; %grab the trial order from a random participant each loop (shouldn't really matter, but do just in case)
    agent.blockOrder = behav_data{rand_subjnum}.blockOrder; %grab the trial order from a random participant each loop (shouldn't really matter, but do just in case)

    % Use fitted values to get choice probabilities from model
    [~, simdata{isub}] = simulate_AET_task_new(task, model, agent, sim_fitted_params(:, isub)');

end

end