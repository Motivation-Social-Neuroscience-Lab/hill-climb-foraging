function modout = EMfit_AET(behav_data, task, model, lb, ub, print_progress, print_visuals)
% Hierarchical Bayesian fitting using EM algorithm for AET task
%
% INPUTS:
%   behav_data: 1 x nsubj cell array, each cell contains data per block
%   task: task structure from buildTask
%   model: model structure from model table
%   lb, ub: lower and upper bounds for parameters
%   print_progress: show progress messages (default true)
%
% OUTPUT:
%   modout: structure with fitted parameters and model statistics

% Meijia Li
% Date: 13/11/2025
% updated 19/11/2025 for AET Task (Emma Scholey)

arguments
    behav_data (1, :) {mustBeA(behav_data, 'cell')}
    task struct
    model struct
    lb (1, :) double
    ub (1, :) double
    print_progress logical = true
    print_visuals logical = false
end

%% Setup
if print_progress
    fprintf('Fitting hierarchical model using EM algorithm...\n');
end

nsubj = length(behav_data);
npar = length(model.paramNames);

% Ensure bounds are column vectors
lb = lb(:);
ub = ub(:);

fprintf('Model parameters: %s\n', strjoin(model.paramNames, ', '));
fprintf('Bounds dimensions: lb=%s, ub=%s\n', mat2str(size(lb)), mat2str(size(ub)));

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

% EM algorithm parameters
convCrit = 0.001;
maxiter = 800;
options = optimoptions(@fminunc, 'Display', 'off', 'Algorithm', 'quasi-newton');

% %% ==================== INITIALIZATION ====================
% initialise group-level parameter mean and variance - Gaussian space
posterior_mu     = randn(npar, 1);
posterior_sigma2 = repmat(100, npar, 1); % Start with wide prior

% Initialize tracking variables
NPL = zeros(nsubj, maxiter);
NPL_old = -Inf;
NLL = zeros(1, maxiter);
NLPrior = zeros(nsubj, maxiter);

%% EM Algorithm
for iiter = 1:maxiter

    % Initialize storage
    fitted_params = zeros(npar, nsubj);
    hessians = zeros(npar, npar, nsubj);

    % build prior gaussian pdfs to calculate P(h|O):
    prior_mu     = posterior_mu;
    prior_sigma2 = posterior_sigma2;
    sigma = sqrt(prior_sigma2);
    %prior_logpdf = @(x) sum(log(normpdf(x, prior_mu, sqrt(prior_sigma2)))); % calculates separate normpdfs per parameter and sums their logs
    prior_logpdf = @(x) sum((-log(sigma)) - (0.5.*log(2*pi)) - (((x-prior_mu).^2) ./ (2.*(sigma.^2)))); % Calculate logpdf by hand to avoid over/underflow errors

    % --- EXPECTATION STEP ---

    parfor isubj = 1:nsubj

        % Initialize parameters
        if iiter > 1
            % Sample from prior distribution
            params_start = normrnd(prior_mu, sqrt(prior_sigma2), npar, 1);
        else
            % First iteration: random start
            params_start = randn(npar, 1);
        end

        % Extract data for this subject (avoid complex indexing in parfor)
        subject_data = behav_data{isubj};

        % Define objective function: NLL + prior
        f = @(params_in) compute_AET_objective(...
            params_in, task, model, subject_data, prior_logpdf, lb, ub);

        % Optimize
        [params_opt, fval, ~, ~, ~, hess_out] = fminunc(f, params_start, options);

        % Store results
        fitted_params(:, isubj) = params_opt; % in Gaussian space
        hessians(:, :, isubj) = hess_out;
        NPL(isubj, iiter) = fval;
        NLPrior(isubj, iiter) = -prior_logpdf(params_opt);
    end

    % --- MAXIMIZATION STEP ---
    [this_mu, this_sigma2, flagcov, ~] = compGauss_ms(fitted_params, hessians); % compute gaussians and sigmas per parameter
    if flagcov == 1 % update only if hessians okay
        posterior_mu = this_mu;
        posterior_sigma2 = this_sigma2;
    end

    % Check convergence
    if print_progress
        fprintf('Iteration %d: NPL = %.2f (change: %.4f)\n', ...
            iiter, sum(NPL(:, iiter)), abs(sum(NPL(:, iiter)) - NPL_old));
    end

    if abs(sum(NPL(:, iiter)) - NPL_old) < convCrit && flagcov == 1
        if print_progress
            fprintf('\n✓ Converged at iteration %d!\n', iiter);
        end
        break
    end

    NPL_old = sum(NPL(:, iiter));

    if print_visuals == true
        tiledlayout('flow'); % TODO: find better way than 'flow', e.g., using model_id to determine number of panels...
        nexttile;

        NLL(iiter) = sum(NPL(:, iiter)) - sum(NLPrior(:, iiter)); % compute NLL manually, just for visualisation
        plot(sum(NPL(:, 1:iiter)), 'b'); hold on;
        plot(NLL(1:iiter), 'r');
        if iiter == 1
            leg = legend({'NPL','NLL'},'Autoupdate','off');
        end
        title(['AET' ' - ' strrep(num2str(model.modelNumber),'_',' ')]);
        xlabel('EM iteration');
        setfp(gcf);
        drawnow;

        % trying plotting prior (vs posterior)
        for ipar = 1:npar
            nexttile;

            mu = posterior_mu(ipar);
            sigma = sqrt(posterior_sigma2(ipar));

            %// Plot curve
            x = linspace(-5*sigma, 5*sigma, 200) + mu;
            plot(x, normpdf(x, prior_mu(ipar), sqrt(prior_sigma2(ipar)))); hold on;
            plot(x, normpdf(x, mu, sigma)); hold on;
            drawnow;
        end
    end
end

% Final covariance matrix
[~, ~, ~, covmat_out] = compGauss_ms(fitted_params, hessians, 2);

% Print if didn't converge before max number of iterations
if iiter == maxiter
    if print_progress == true, fprintf('...maximum number of iterations reached\n'); end
end

%% Package output
modout = struct();
modout.model_name = sprintf('Model_%d', model.modelNumber);
modout.model = model;
modout.date = datestr(now);
modout.nsubj = nsubj;
modout.npar = npar;
modout.param_names = model.paramNames;

% Transform parameters back to original space
modout.fitted_params_real = zeros(npar, nsubj);
for isubj = 1:nsubj
    modout.fitted_params_real(:, isubj) = gauss2real(...
        fitted_params(:, isubj), lb, ub);
end
modout.fitted_params_gaussian = fitted_params;
modout.hessians = hessians;
modout.bounds.lb = lb;
modout.bounds.ub = ub;

% In Gaussian space
modout.gauss_mu      = posterior_mu;
modout.gauss_sigma2  = posterior_sigma2;
modout.gauss_cov     = covmat_out;

% In real (model) space
modout.real_mu      = gauss2real(posterior_mu, lb, ub);

% Correlation matrix
try
    modout.gauss_corr = corrcov(covmat_out);
catch
    covmat_out = (covmat_out + covmat_out') / 2;
    modout.gauss_corr = corrcov(covmat_out);
end

% Model fit statistics
modout.npl = NPL(:, iiter);
modout.NLPrior = NLPrior(:, iiter);
modout.nll = NPL(:, iiter) - NLPrior(:, iiter);
modout.ntrials = ntrials;

% AIC and BIC
modout.aic = -2*(-modout.nll) + 2*npar;
modout.bic = -2*(-modout.nll) + log(ntrials)*npar;

% Convergence info
modout.convCrit = convCrit;
modout.maxit = maxiter;
modout.iiter = iiter;

% Laplace approximation for model evidence
goodHessian = zeros(1, nsubj);
L = zeros(1, nsubj);
for isubj = 1:nsubj
    try
        hHere = logdet(hessians(:,:,isubj), 'chol');
        L(isubj) = -NPL(isubj,iiter) - 0.5*hHere + (npar/2)*log(2*pi);
        goodHessian(isubj) = 1;
    catch
        try
            hHere = logdet(hessians(:,:,isubj));
            L(isubj) = -NPL(isubj,iiter) - 0.5*hHere + (npar/2)*log(2*pi);
            goodHessian(isubj) = 0;
        catch
            warning('Could not calculate log model evidence for subject %d', isubj);
            goodHessian(isubj) = -1;
            L(isubj) = nan;
        end
    end
end

% Handle NaN and imaginary values
L(isnan(L)) = mean(L, 'omitnan');
L(imag(L) ~= 0) = mean(real(L), 'omitnan');

modout.lme = L;
modout.goodHessian = goodHessian;

%% POST-FITTING DIAGNOSTICS
figure;

for iP = 1:npar
    subplot(2, npar, iP);

    % Individual estimates
    histogram(modout.fitted_params_real(iP, :), 20, 'Normalization', 'pdf');
    hold on;

    mu = gauss2real(modout.gauss_mu(iP), lb, ub);
    sigma = sqrt(modout.gauss_sigma2(iP));
    % Fitted group distribution   %% ES - FIX: change gauss to real space
    x = linspace(lb(iP), ub(iP), 200);
    plot(x, normpdf(x, mu, sigma), ...
        'r-', 'LineWidth', 2);

    xlabel(model.paramNames{iP});
    title('Individual Distribution');
    legend('Empirical');
end