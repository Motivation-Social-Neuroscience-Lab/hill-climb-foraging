function modout = MLEfit_AET(behav_data, task, model, lb, ub)
% MLE fitting for AET task
%
% INPUTS:
%   behav_data: 1 x nsubj cell array, each cell contains data per block
%   task: task structure from buildTask
%   model: model structure from model table
%   lb, ub: lower and upper bounds for parameters
%
% OUTPUT:
%   modout: structure with fitted parameters and model statistics

% Emma Scholey
% Date 9 March 2026

niter = 50;
nsubj = length(behav_data);
npar = length(model.paramNames);

% Get number of valid trials per subject
ntrials = zeros(nsubj, 1);
for isubj = 1:nsubj
    total_trials = 0;
    for iBlock = 1:task.nBlocks
        block_data = behav_data{isubj}{iBlock};
        total_trials = total_trials + sum(block_data.response ~= 8888); % exclude missed trials
    end
    ntrials(isubj) = total_trials;
end

options = optimoptions('fmincon','Display','none'); % don't display

% Ensure bounds are column vectors
lb = lb(:);
ub = ub(:);

% initialise containers
min_nll = zeros([nsubj 1]);
min_nll_params = zeros([npar nsubj]);
BIC = zeros([nsubj 1]);

for isubj = 1:nsubj

    isubj
    % Extract data for this subject
    subject_data = behav_data{isubj};

    NLL_eval = zeros([niter, 1]);
    fitted_params = zeros([niter, npar]);

    %Run fmincon
    parfor ii = 1:niter
        params0 = gauss2real(randn(npar, 1), lb, ub)';

        f = @(x0)simulate_AET_model(task,model,subject_data,x0);
        [fitted_params(ii,:),NLL_eval(ii)] = fmincon(f,params0,[],[],[],[],lb,ub,[],options);
    end

    % Find the best fitting parameter values
    min_nll(isubj) = min(NLL_eval);   % minimum negative log likelihood over all starting positions
    ix = find(min_nll(isubj) == NLL_eval);    % indices of location of minimum, to find the corresponding best fit parameters
    min_nll_params(:,isubj) = fitted_params(ix(1),:)'; % get corresponding parameter values at lowest NLL

    % Calculate BIC
    BIC(isubj) = npar * log(ntrials(isubj)) + 2*min_nll(isubj);
end

%% Package output
modout = struct();
modout.model_name = sprintf('Model_%d', model.modelNumber);
modout.model = model;
modout.date = datestr(now);
modout.nsubj = nsubj;

% Parameters
modout.npar = npar;
modout.param_names = model.paramNames;
modout.fitted_params_real = min_nll_params;
modout.bounds.lb = lb;
modout.bounds.ub = ub;

% Model fit statistics
modout.nll = min_nll;
modout.ntrials = ntrials;

% BIC
modout.bic = BIC;