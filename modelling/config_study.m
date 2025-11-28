function cfg = config_study(study, fit_flag)
% CONFIG_STUDY Configuration settings for AET studies
%
% Author: Emma Scholey
% Date: 2024

cfg = struct();

switch study
    case 'v1'
        %% Version identifier
        cfg.version = 'v1';
        cfg.excluded_subjects = [4, 6, 17, 18, 21, 26, 30, 38, 43];

        % Task parameters
        cfg.task.env = [11 99]; % 11 = easy task, 99 = hard task
        cfg.task.nBlocks = 6;
        if fit_flag == 1
            cfg.task.blockTime = 400; % block time for fitting (longer than needed), since fitting relies on actual recorded trials rather than time
        else
            cfg.task.blockTime = 300; % max time in block (seconds) for simulations - longer for MRI
        end
        cfg.task.decisionTime = 1; % time taken to make decision (seconds)
        cfg.task.acceptTime = 9; % time taken to pursue prey (seconds) - shorter for MRI
        cfg.task.rejectTime = 3; % time taken to avoid prey (seconds)
        cfg.task.timeStep = 1; % assume updates happen at each second
        cfg.task.magnitudes = [0.2 0.4 0.6]; % magnitudes on grip force device
        cfg.task.effortLevels = [1 2 3]; % arbitrary level unit
        cfg.task.reward = 2; % set the same as the mid effort level
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});

        % File paths
        cfg.paths.dataDerived = '../../data_derived/v1/';
        cfg.paths.dataRaw = '../../data_raw/v1/';

    case 'v3'
        %% Version identifier
        cfg.version = 'v3';
        cfg.excluded_subjects = [1:16, 30, 34, 42];

        % Task parameters
        cfg.task.env = [11 99]; % 11 = easy task, 99 = hard task
        cfg.task.nBlocks = 6;
        if fit_flag == 1
            cfg.task.blockTime = 400; % block time for fitting (longer than needed), since fitting relies on actual recorded trials rather than time
        else
            cfg.task.blockTime = 300; % max time in block (seconds) for simulations - longer for MRI
        end
        cfg.task.decisionTime = 1; % time taken to make decision (seconds)
        cfg.task.acceptTime = 9; % time taken to pursue prey (seconds) - shorter for MRI
        cfg.task.rejectTime = 3; % time taken to avoid prey (seconds)
        cfg.task.timeStep = 1; % assume updates happen at each second
        cfg.task.magnitudes = [0.1 0.4 0.7]; % magnitudes on grip force device
        cfg.task.effortLevels = [1 2 3]; % arbitrary level unit
        cfg.task.reward = 2; % set the same as the mid effort level
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});

        % File paths
        cfg.paths.dataDerived = '../../data_derived/v3/';
        cfg.paths.dataRaw = '../../data_raw/v3/';

    case 'mri'
        %% Version identifier
        cfg.version = 'mri';
        cfg.excluded_subjects = [10, 31];

        % Task parameters
        cfg.task.env = [11 99]; % 11 = easy task, 99 = hard task
        cfg.task.nBlocks = 6;
        if fit_flag == 1
            cfg.task.blockTime = 400; % block time for fitting (longer than needed), since fitting relies on actual recorded trials rather than time
        else
            cfg.task.blockTime = 360; % max time in block (seconds) for simulations - longer for MRI
        end
        cfg.task.decisionTime = 1; % time taken to make decision (seconds)
        cfg.task.acceptTime = 8; % time taken to pursue prey (seconds) - shorter for MRI
        cfg.task.rejectTime = 3; % time taken to avoid prey (seconds)
        cfg.task.timeStep = 1; % assume updates happen at each second
        cfg.task.magnitudes = [0.2 0.4 0.6]; % magnitudes on grip force device
        cfg.task.effortLevels = [1 2 3]; % arbitrary level unit
        cfg.task.reward = 2; % set the same as the mid effort level
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});

        % File paths
        cfg.paths.dataDerived = '../../data_derived/mri/';
        cfg.paths.dataRaw = '../../data_raw/mri/';

    case 'online'
        %% Version identifier
        cfg.version = 'online';
        cfg.excluded_subjects = []; % participants already excluded from behav_summary

        % Task parameters
        cfg.task.env = [11 99]; % 11 = easy task, 99 = hard task
        cfg.task.nBlocks = 4;
        if fit_flag == 1
            cfg.task.blockTime = 400; % block time for fitting (longer than needed), since fitting relies on actual recorded trials rather than time
        else
            cfg.task.blockTime = 300; % max time in block (seconds) for simulations - longer for MRI
        end
        cfg.task.decisionTime = 2.5; % time taken to make decision (seconds)
        cfg.task.acceptTime = 5; % time taken to pursue prey (seconds) - shorter for MRI
        cfg.task.rejectTime = 3; % time taken to avoid prey (seconds)
        cfg.task.timeStep = 1; % assume updates happen at each second
        cfg.task.magnitudes = [0.3 0.5 0.7]; % magnitudes on grip force device
        cfg.task.effortLevels = [1 2 3]; % arbitrary level unit
        cfg.task.reward = 2; % set the same as the mid effort level
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});

        % File paths
        cfg.paths.dataDerived = '../../data_derived/online/';
        cfg.paths.dataRaw = '../../data_raw/online/';

end



