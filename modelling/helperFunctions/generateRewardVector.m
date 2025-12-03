function reward_vec = generateRewardVector(mode_credits,min_credits,max_credits,nTrials)
% custom function for AET project, generates a reward vector of nTrials
% based on provided mode, min and max credits

% Emma Scholey, 3 Dec 2025
vals = min_credits:max_credits;
d = abs(vals - mode_credits);
p = (1./(1+d).^2);
p = p/sum(p);

% do discreteinvrnd (inversion method for a discrete distribution with
% probability mass vector p)

idx = discreteinvrnd(p,nTrials,1);
reward_vec = vals(idx); 
% reward_vec = zeros(nTrials,1); % Preallocate memory
% for i = 1:nTrials*1
%     u = rand;
%     I = find(u < cumsum(p));
%     reward_vec(i) = min(I);
% end