function params_real = gauss2real(params, lb, ub)

% Function to transform gaussian parameters to real bounded parameter values for all AET models;

% arguments
%     params (:, 1) {mustBeNumeric} % in Gaussian space
%     lb (:, 1) {mustBeNumeric} % lower bound
%     ub (:, 1) {mustBeNumeric} % upper bound

% Emma Scholey, 19 November 2025

params_real = zeros(size(params));
for i = 1:length(params)
    if isinf(lb(i)) && isinf(ub(i)) % real (-inf, inf)
        params_real(i) = params(i);

        %ES - could add positive real here to capture beta lower
        %values, but low priority. : exponential distribution

    elseif lb(i) == 0 && ub(i) == 1 % unit (0,1): logistic transform
        %params_real(i) = 1 ./ (1 + exp(-params(i))); % logistic transform
        params_real(i) = normcdf(params(i));

    else % bounded (lb, ub): logistic scaled to bounds
        params_real(i) = 1 ./ (1 + exp(-params(i)));
        params_real(i) = lb(i) + (ub(i) - lb(i)) .* params_real(i);

    end
end
