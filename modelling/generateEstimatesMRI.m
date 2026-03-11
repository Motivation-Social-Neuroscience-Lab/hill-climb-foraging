%% generating trial-by-trial estimates from computational model for MRI 1st-level GLM
% Emma Scholey 5 April 2024
% last updated January 2026

clear
close all

addpath('./helperFunctions')

modelTable = readtable('./AETModelTable.xlsx');

%% user options

% model options
modelNum = 13;

study_version = 'mri';
param_type = 'fit'; % which parameters to simulate {fit, median}

fit_type = 'MAP'; % MAP or MLE

%% set up model and task

% which subjects
name_subj = [101:104, 106:110, 112:131, 133:141]; % The file (subject) numbers of the files to be used in the analysis
nsims = length(name_subj);

% load study settings
fit_flag = 1;
config = config_study(study_version, fit_flag);

% load and prepare dataframe container for simulations
behav_data = buildData(config, fit_flag, nsims);

% who do we have? so we cna make folders for them later
matFiles = dir(['../../data_raw/mri/behaviour/main/*MRI.mat']);

%matFiles =
save_dir = ['/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/sub-'];

% exclude subjects
for i = 1:length(matFiles)
    ix(i) = ismember(str2double(matFiles(i).name(1:3)), name_subj);
end

matFiles = matFiles(ix);

%% generate simulated data

for m = modelNum % for all models

    % load all subjects' fitted parameters

    switch fit_type
        case 'MAP'
            load([config.paths.data_fit, 'fitting_hierarchical_M' num2str(modelNum)]);
        case 'MLE'
            load([config.paths.data_fit, 'fitting_MLE_M' num2str(modelNum)]);
    end

    switch param_type
        case 'fit'
            params = modout.fitted_params_real; %simulate each subject once with their estimate
        case 'median'
            params = repmat(median(modout.fitted_params_real,2), [1, nsims]); %simulate median of fit parameters
    end

    for isub = 1:nsims

        id = matFiles(isub).name(2:3); % MRI ID
        agent = behav_data{isub};

        [~, results] = simulate_AET_model(config.task, modout.model, agent, params(:, isub)');

        % save results
        writetable(results,[save_dir,id,'/model_estimates_M',num2str(m),'_', param_type,'_',fit_type, '.csv'])

    end
end
