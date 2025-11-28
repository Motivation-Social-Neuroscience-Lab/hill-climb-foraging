function [params] = buildParams(model)

param_names = {'kOffer','beta', 'alpha', 'weight'};

lb = [0,0,0, 0]; 
ub = [3,50,1,1];

% always included
kOffer = true;
beta = true;
alpha = true;

if contains(model.discountFunction, 'weight')
    weight = true;
else 
    weight = false;
end

params_include = [kOffer, beta, alpha, weight];

params.lb = lb(params_include);
params.ub = ub(params_include);
params.names = param_names(params_include);

