%% Hierarchical Bayesian Fitting for EPT Models
% This script fits models using hierarchical EM algorithm instead of
% individual fmincon optimization. This improves parameter recovery,
% especially for bounded parameters like alpha.
%
% Meijia Li EPT
% Date: 13/11/2025
% updated 19/11/2025 for AET task (Emma Scholey)

clear
close all

addpath('./helperFunctions')

%% ============================================================================
%  STEP 1: USER OPTIONS
%% ============================================================================

% Which models to fit
modelNumbers = [1:3];

% Fitting options
study_version = 'v3';  % 'v1', 'v3', or 'mri'
fit_flag = 1; % are we fitting?
fit_type = 'MAP'; % MLE or MAP?

% Load model table
modelTable = readtable('./AETModelTable.xlsx');

print_progress = true;
print_visuals = false;


switch fit_type

    %% ============================================================================
    % MAP FITTING
    %% ============================================================================
    case 'MAP'
        for iModel = 1:length(modelNumbers)
            modelNum = modelNumbers(iModel);
            %% ============================================================================
            % SETUP
            fprintf('\n=== HIERARCHICAL BAYESIAN FITTING FOR AET ===\n');
            fprintf('Model: %d\n', modelNum);
            fprintf('Version: %s\n', study_version);

            % Load task
            config = config_study(study_version, fit_flag);

            % Load participant data
            behav_data = buildData(config, fit_flag, []);

            % Load model specification
            model = table2struct(modelTable(modelTable.modelNumber == modelNum,:));

            % Get parameter names and bounds
            [params] = buildParams(model);
            model.paramNames = params.names;

            nSubj = length(behav_data);
            nParams = length(model.paramNames);

            fprintf('Parameters: %s\n', strjoin(model.paramNames, ', '));
            fprintf('Subjects: %d\n', nSubj);

            %% ============================================================================
            % RUN HIERARCHICAL FITTING

            fprintf('\n=== RUNNING HIERARCHICAL EM ALGORITHM ===\n');

            % Run hierarchical EM fitting
            modout = EMfit_AET(behav_data, config.task, model, params.lb, params.ub, print_progress, print_visuals);

            fprintf('\n=== CALCULATING INTEGRATED BIC ===\n');

            modout.bicint = cal_BICint_ms(modout, behav_data, config.task, model, 2000, print_progress);
            modout.choiceprob_median_R2 = choiceProbR2(modout.fitted_params_real, config.task, model, behav_data);
            %% ============================================================================
            %  SAVE RESULTS

            % Create output directory
            outputDir = [config.paths.data_fit];

            if ~exist(outputDir, 'dir')
                mkdir(outputDir);
                fprintf('Created directory: %s\n', outputDir);
            end

            % Save results
            save_name = sprintf('%s/fitting_hierarchical_M%d', outputDir, modelNum);
            save(save_name, 'modout', '-v7.3');

            %% ============================================================================
            %  DISPLAY SUMMARY

            fprintf('\n=== FITTING SUMMARY ===\n');
            fprintf('Model: %d\n', modelNum);
            fprintf('Converged at iteration: %d/%d\n', modout.iiter, modout.maxit);

            fprintf('\nGroup-level parameter estimates:\n');
            for iP = 1:nParams
                fprintf('  %s: %.3f\n', model.paramNames{iP}, ...
                    modout.real_mu(iP));
            end

        end
        fprintf('\nFitted %d model(s): %s\n', length(modelNumbers), mat2str(modelNumbers));

        %% ============================================================================
        % MLE FITTING
        %% ============================================================================
    case 'MLE'
        for iModel = 1:length(modelNumbers)
            modelNum = modelNumbers(iModel);
            %% ============================================================================
            % SETUP
            fprintf('\n=== MLE FITTING FOR AET ===\n');
            fprintf('Model: %d\n', modelNum);
            fprintf('Version: %s\n', study_version);

            % Load task
            config = config_study(study_version, fit_flag);

            % Load participant data
            behav_data = buildData(config, fit_flag, []);

            % Load model specification
            model = table2struct(modelTable(modelTable.modelNumber == modelNum,:));

            % Get parameter names and bounds
            [params] = buildParams(model);
            model.paramNames = params.names;

            nSubj = length(behav_data);
            nParams = length(model.paramNames);

            fprintf('Parameters: %s\n', strjoin(model.paramNames, ', '));
            fprintf('Subjects: %d\n', nSubj);

            %% ============================================================================
            % RUN MLE FITTING

            fprintf('\n=== RUNNING MAXIMUM LIKELIHOOD ESTIMATION ===\n');

            modout = MLEfit_AET(behav_data, config.task, model, params.lb, params.ub); 

            modout.choiceprob_median_R2 = choiceProbR2(modout.fitted_params_real, config.task, model, behav_data);

            %% ============================================================================
            %  SAVE RESULTS

            % Create output directory
            outputDir = [config.paths.data_fit];

            if ~exist(outputDir, 'dir')
                mkdir(outputDir);
                fprintf('Created directory: %s\n', outputDir);
            end

            % Save results
            save_name = sprintf('%s/fitting_MLE_M%d', outputDir, modelNum);
            save(save_name, 'modout', '-v7.3');

        end
        fprintf('\nFitted %d model(s): %s\n', length(modelNumbers), mat2str(modelNumbers));

end