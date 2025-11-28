function fval = compute_AET_objective(params_in, task, model, ...
    subject_data, prior_logpdf, lb, ub)

% Define objective function for optimiser, convert Gaussian parameters to
% real model space, and check for errors

% Emma Scholey, 19 November 2025
% based on code from Meijia Li Nov 2025

    % Ensure inputs are correct size
    params_in = params_in(:);
    lb = lb(:);
    ub = ub(:);
    
    % Transform parameters to original space
    params = gauss2real(params_in, lb, ub);
    
    % Ensure parameters are within bounds
    below_lb = params < lb;
    above_ub = params > ub;
    
    if any(below_lb) || any(above_ub)
        fval = 1e10;
        return;
    end
    
    % Check for invalid values
    if any(isnan(params)) || any(isinf(params))
        fval = 1e10;
        return;
    end
    
    % Compute negative log likelihood
    try
        [nll, ~] = simulate_AET_task_new(task, model, subject_data, params');
        
        if isnan(nll) || isinf(nll)
            fval = 1e10;
            return;
        end
    catch
        fval = 1e10;
        return;
    end
    
    % *** ADD CHECK FOR EXTREME PRIOR VALUES ***
    try
        nlp = -prior_logpdf(params_in);
        
        % Check if prior is valid and not extremely unlikely
        if isnan(nlp) || isinf(nlp) || nlp > 1e8
            fval = 1e10;
            return;
        end
    catch
        fval = 1e10;
        return;
    end
    
    % Return negative log posterior
    fval = nll + nlp;
end