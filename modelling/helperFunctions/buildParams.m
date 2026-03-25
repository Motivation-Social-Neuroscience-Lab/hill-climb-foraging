function [params] = buildParams(model)
% set up parameters depending on model options

param_names = {'kOffer','beta', 'alpha'};%, 'weight', 'bE_easy','bE_hard', 'bias'};

lb = [0,0,0];%, 0,0,0, -5];
ub = [5,50,1];%, 1,5,5, 5];
% ES: Theoretically, kOffer upper bound depends on how R set - max is 2 if R is
% dummy coded to 2. max is 4 if R takes real average credits (=4 max).
% These values give V = 0 when Effort = 1 (assuming max k, w = 0).


% always included
kOffer = true;
beta = true;

switch model.learnFunction
    case {'expected', 'response_history'}%,'exerted', 'reward'}
        alpha = true;
        %bE_easy = false; bE_hard = false;
 
    case {'real'}
        alpha = false;
        %bE_easy = false; bE_hard = false;
    
    case 'fixed'
        alpha = false;
        %bE_easy = true; bE_hard = true;
end

% switch model.discountFunction
%     case 'weight'
%         weight = true;
%     case {'k','none'}
%         weight = false;
% end

% switch model.bias
%     case 'bias'
%         bias = true;
%     case 'none'
%         bias = false;
% end

params_include = [kOffer, beta, alpha];%, weight, bE_easy, bE_hard, bias];

params.lb = lb(params_include);
params.ub = ub(params_include);
params.names = param_names(params_include);

