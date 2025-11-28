function bicint = cal_BICint_ms(fitted_model, behav_data, task, model, nsample, print_progress)
%function [bicint] = cal_BICint_ms(fitted_model, behav_data, nsample, print_progress)
% Calculates integrated Bayesian Information Criterion.
% 
% Author: MK Wittmann, 2017
% Edited by Todd Voge 2024
% Edited Emma Scholey 19 Nov 2025 for AET 

arguments
    fitted_model struct
    behav_data (1, :) {mustBeA(behav_data, 'cell')} % 1 x nsubj cell array of all subjects data
    task struct
    model struct
    nsample double = 2000
    print_progress logical = true
end

npar    = fitted_model.npar;
ntrials = fitted_model.ntrials;
nsubj = numel(behav_data);

lb = fitted_model.bounds.lb;
ub = fitted_model.bounds.ub;

% info for normrnd, flip if in wrong orientation
mu = fitted_model.gauss_mu;
if size(mu, 2) > size(mu, 1)
    mu = mu';
end
sigma = sqrt(fitted_model.gauss_sigma2);
if size(sigma, 2) > size(sigma, 1)
    sigma = sigma';
end

% Get integrated nll by sampling nll from group gaussian
if print_progress == true
    fprintf([fitted_model.model_name ' - BICint:   '])
end

iLog = nan(nsubj, 1); % proxy for integrated log
for isubj = 1:nsubj

    subnll = nan(1, nsample);
    params = nan(fitted_model.npar, nsample);

    agent = behav_data{isubj};

    Gsamples = normrnd(repmat(mu, 1, nsample), repmat(sigma, 1, nsample)); % samples from gaussian distribution found during EM; draw anew for each subject

    % for each subject, get NLL for input params from gaussian
    parfor k = 1:nsample
        % Convert Gaussian parameters to model space
        params(:,k) = gauss2real(Gsamples(:,k), lb, ub);

        % Compute negative log likelihood
        subnll(k) = simulate_AET_task_new(task, model, agent, params(:, k)');
    end

    % Update the progress of the loop
    if print_progress == true
        ndigits_curr = numel(num2str(isubj)); % find the number of digits in the current number of the loop (e.g., 12 = two digits)
        ndigits_total = numel(num2str(nsubj)); % find the # of digits in the numel of nsubj
        
        % Print (to command window) the current progress every 10 subjects
        if isubj == 1
             fprintf([num2str(isubj), '/', num2str(nsubj)]); 
        elseif mod(isubj, 10) == 0 || isubj == nsubj
            fprintf(repmat('\b', 1, ndigits_curr + ndigits_total + 1)) % +1 to remove the "/" (e.g., 34/80) and the extra space at the front in the output
            fprintf([num2str(isubj), '/', num2str(nsubj)]);
        end
    end

    iLog(isubj) = log(sum(exp(-subnll)) / nsample);
    if iLog(isubj) == inf
        keyboard
    end
end

% Compute BICint
bicint  = -2 * sum(iLog) + npar * log(sum(ntrials)); % integrated BIC
fprintf('\n');

end