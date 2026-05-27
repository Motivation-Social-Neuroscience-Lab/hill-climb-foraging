function [params] = buildParams(model)
% set up parameters depending on model options

param_names = {'kOffer','beta', 'alpha'};

lb = [0,0,0];
ub = [5,50,1];

% always included
kOffer = true;
beta = true;

switch model.learnFunction
    case {'expected', 'response_history'}
        alpha = true;
 
    case 'real'
        alpha = false;
end


params_include = [kOffer, beta, alpha];

params.lb = lb(params_include);
params.ub = ub(params_include);
params.names = param_names(params_include);

