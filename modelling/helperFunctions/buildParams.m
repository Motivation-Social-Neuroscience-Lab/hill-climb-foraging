function [params] = buildParams(model)
% set up parameters depending on model options

param_names = {'kOffer','beta', 'alpha', 'weight', 'bias'};

lb = [0,0,0, 0, -5];
ub = [5,50,1,1, 5];
% ES: Theoretically, kOffer upper bound depends on how R set - max is 2 if R is
% dummy coded to 2. max is 4 if R takes real average credits (=4 max).
% These values give V = 0 when Effort = 1 (assuming max k, w = 0). 


% always included
kOffer = true;
beta = true;

switch model.learnFunction
    case {'expected', 'exerted', 'reward', 'response_history'}
        alpha = true;
    % case 'fixed'
    %     alpha = false;
    %     oppCost_easy = true;
    %     oppCost_hard = true;
    case 'real'
        alpha = false;
end

switch model.discountFunction
    case 'weight'
        weight = true;
    case {'none', 'weight_k'}
        weight = false;
end

switch model.bias
    case 'bias'
        bias = true;
    case 'none'
        bias = false;
end

params_include = [kOffer, beta, alpha, weight, bias];

params.lb = lb(params_include);
params.ub = ub(params_include);
params.names = param_names(params_include);

