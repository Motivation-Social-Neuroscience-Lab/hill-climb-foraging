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
        cfg.task.credits = [4,2,6]; % mode, min, max, for defining distribution for simulating credit structure
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});
        cfg.experienced_reward = 1.3;
        cfg.experienced_effort = 1.1; 

        % File paths
        cfg.paths.data_fit = '../data/fit/v1/';
        cfg.paths.data_behav = '../data/behavioural/v1/';

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
        cfg.task.credits = [3,2,4]; % mode, min, max, for defining distribution for simulating credit structure
        cfg.task.magnitudeToLevel = containers.Map({0.1, 0.4, 0.7}, {1, 2, 3});
        cfg.experienced_reward = 1.3;
        cfg.experienced_effort = 1; 

        % File paths
        cfg.paths.data_fit = '../data/fit/v3/';
        cfg.paths.data_behav = '../data/behavioural/v3/';


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
        cfg.task.credits = [4,2,6]; % mode, min, max, for defining distribution for simulating credit structure
        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});
        cfg.experienced_reward = 1.3;
        cfg.experienced_effort = 1; 

        % File paths
        cfg.paths.data_fit = '../data/fit/mri/';
        cfg.paths.data_behav = '../data/behavioural/mri/';


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
        cfg.task.credits = [1,1,1]; % mode, min, max, for defining distribution for simulating credit structure

        cfg.task.magnitudeToLevel = containers.Map({0.2, 0.4, 0.6}, {1, 2, 3});

        % File paths
        cfg.paths.data_fit = '../data/fit/online/';
        cfg.paths.data_behav = '../data/behavioural/online/';


end



