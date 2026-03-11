function task = buildTask(funcOptions)

task.env = [11 99]; % 11 = easy task, 99 = hard task

if strcmp(funcOptions.type, 'fit')
    task.blockTime = 400; % give them longer than they need - we're fitting per trial, not by time
else
    if strcmp(funcOptions.version, 'mri')
        task.blockTime = 360; % max time in block % 360s in experiment
    else
        task.blockTime = 300; % max time in block % 300s in experiment
    end
end

task.nBlocks = 6; % 6 blocks in total 

task.taskTime = task.blockTime*task.nBlocks; % max time in task (over 6 blocks) 

task.decisionTime = 1; % time taken to make decision, simplifying assumption here that this is 1 second

if strcmp(funcOptions.version, 'mri')
    task.acceptTime = 8; % time taken to pursue prey
    task.rejectTime = 3; % time taken to avoid prey
else 
    task.acceptTime = 9;
    task.rejectTime = 3; 
end

task.timeStep = 1; % assume updates happen at each second
task.effortCodes = [111 222 333]; % shape code (low mid high)

if strcmp(funcOptions.version, 'v1') || strcmp(funcOptions.version, 'mri')
    task.magnitudes = [0.2 0.4 0.6]; % magnitudes on grip force device
elseif strcmp(funcOptions.version, 'v3')
    task.magnitudes = [0.1 0.4 0.7];
end

task.effortLevels = [1 2 3]; % arbritrary level unit

task.reward = 2; % set the same as the mid effort level to make consistent (on average they recive 3 or 4 credits per successful exerted trial) 

if  strcmp(funcOptions.version, 'v3') || strcmp(funcOptions.version, 'mri')
    task.medianReward = 3;
elseif strcmp(funcOptions.version, 'v1')
    task.medianReward = 4;
end

% % start estimates for modelling 
% task.startAvgEffort = task.effortLevels(2); % initialise to average effort for an accepted mid effort trial
% task.startAvgReward = task.reward; % initialise to average reward received for an accepted trial
