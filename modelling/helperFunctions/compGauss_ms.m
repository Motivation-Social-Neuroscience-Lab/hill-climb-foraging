function [mu, sigma2, flagsigma, covmat] = compGauss_ms(fitted_params, hessians, docovar)
% compute group-level gaussian from fminunc computed parameters and their covariances
% MKW, 2017
% Edited by Todd Vogel 2024
%
% INPUT:    
%   fitted_params:  fitted parameters (npar x nsub matrix)     
%   hessians:  individual-level hessians(npar x npar x nsub)
%   docovoar: if true, computes covariance matrix in addition
%
% OUTPUT:
%   mu - group mean 
%   sigma2 - group variance
%   flagcov - flag indicating whether model variance was calculated successfully 
%   covmat - full covariance matrix; is [] if docovar == false

arguments
    fitted_params (:, :) {mustBeNumeric} % nparams (rows) x nsubj (cols) array
    hessians (:, :, :) {mustBeNumeric} % nparams x nparams x nsubj array
    docovar logical = false %TV: FIXME REMOVE OR CHANGE?? IS THIS EVER USED????
end

%%
nsub = size(fitted_params, 2);
npar = size(hessians, 1);
covmat = [];

% ------ 1) compute mean: -------------------------------------------------
% Group mean: simple average of individual estimates
mu =  mean(fitted_params, 2);

% ------2) Compute sigma: -------------------------------------------------
% Group variance: accounts for both between-subject variability 
% AND within-subject uncertainty (from Hessian)
sigma2   = zeros(size(hessians, 1),1);
for is = 1:nsub
   sigma2 = sigma2 + fitted_params(:, is).^2 + diag(pinv(hessians(:, :, is)));
end
sigma2 = sigma2./nsub  - mu.^2;


% give error message in case:
if min(sigma2) < 0 || any(isnan(sigma2))
    flagsigma = 0; 
    disp('CovError!');
else 
    flagsigma = 1;  
end % negative values for the variance cannot be

% ----- 3) Optional: Get full covariance matrix----------------------------
if docovar == true
    covmat   = zeros(npar,npar);
    for is = 1:nsub
        covmat = covmat + fitted_params(:,is)*fitted_params(:,is)' - fitted_params(:,is)*mu' - mu*fitted_params(:,is)' + mu*mu' + pinv(hessians(:,:,is));
    end
    covmat = covmat ./ nsub;
end
if det(covmat) <= 0
    fprintf('negative/zero determinant - prior covariance not updated');
end

end