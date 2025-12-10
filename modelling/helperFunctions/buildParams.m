function [params] = buildParams(model)
% set up parameters depending on model options

param_names = {'kOffer','beta', 'alpha', 'weight', 'oppCost_easy', 'oppCost_hard'};

lb = [0,0,0, 0, -5, -5];
ub = [3,50,1,1, 5, 5];

% always included
kOffer = true;
beta = true;

switch model.learnFunction
    case {'expected', 'exerted', 'reward', 'response_history'}
        alpha = true;
        oppCost_easy = false;
        oppCost_hard = false;
    case 'fixed'
        alpha = false;
        oppCost_easy = true;
        oppCost_hard = true;
end

switch model.discountFunction
    case 'weight'
        weight = true;
    case 'none'
        weight = false;
end

params_include = [kOffer, beta, alpha, weight, oppCost_easy, oppCost_hard];

params.lb = lb(params_include);
params.ub = ub(params_include);
params.names = param_names(params_include);

