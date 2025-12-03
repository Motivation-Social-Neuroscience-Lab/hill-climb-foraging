function [negLL, results, response_out] = simulate_AET_model(task,model,agent,agentParams)

% convert parameter array to table to allow indexing
params = array2table(agentParams); params.Properties.VariableNames = model.paramNames;

% set up trial counters
trialTask = 1; % start trials in task counter
trialBlock = 1; % start trials in block counter
timeTask = 0; % start time in task counter
timeBlock = 0; % start time in block counter

blockN = 1; % start in first block

% start with data from first block
response = agent{blockN}.response; % if accepted (1) or waited (0)
cueEffort = agent{blockN}.cueEffort; % either shape cue (v1), or effort level (v3 and mri)
outcomeEffort = agent{blockN}.outcomeEffort; % this will only differ to cueEffort for v1, since probabilistic cue
blockType = agent{blockN}.blockType; % environment type: 11 = easy, 99 = hard
reward = agent{blockN}.reward;

% initialise decision variables, we should rescale the opportunity cost:
% the value/effort rate per timestep, multiplied by
% time taken to accept a trial

switch model.learnFunction
    case {'expected', 'reward'}
        delay = 1;
        bE = task.effortLevels(2);
        bR = task.reward;
    case 'exerted'
        delay = 1;
        bE = task.effortLevels(1); % most likely to accept low effort level
        bR = task.reward;
    case {'expected_tau', 'reward_tau'}
        delay = task.acceptTime;
        bE = task.effortLevels(2)/delay;
        bR = task.reward/delay;
    case 'exerted_tau'
        delay = task.acceptTime;
        bE = task.effortLevels(1)/delay; % most likely to accept low effort level
        bR = task.reward/delay;
end

weight = params.weight;

R = task.reward; % fix reward to 2, equivalent to effort level 2
%R = task.credits(1); % fix at mode credits

oppCost = 0; % opp cost, taking into account pursue time (task.acceptTime)
effortPE = 0; % no PE on first trial 
rewardPE = 0; % no PE on first trial 

alpha = params.alpha;
beta = params.beta;
kOffer = params.kOffer; 

logLikelihood = 0; % for model fitting

df = []; % create empty container to store timestep results
results = cell(1,task.nBlocks);
response_out = cell(1,task.nBlocks);

while blockN <= task.nBlocks

    % t = 0 in trial
    %% encounter effort

    E = cueEffort(trialBlock);

    % calculate opportunity cost given estimate of background value (bR -
    % bE) and delay of accepting
    oppCost = (bR - bE) * delay;

    % compute subjective value
    SV = (1-weight)*(R-kOffer*E^2) - weight*(oppCost);

    % make decision
    pAccept = softmaxAccept(beta, SV, 0); % oppCost will be 0 if backgroundEffort already weighting value

    if isnan(response(trialBlock)) % if simulating data
        response(trialBlock) = (rand(1) < pAccept);     % make a choice of next action
    end

    % log the probability of selected action
    if response(trialBlock) == 1 % if subject accepted
        pSelected = pAccept;
        tau = delay + task.decisionTime;
    elseif response(trialBlock) == 0 % if subject rejected
        pSelected = 1-pAccept;
        tau = task.rejectTime + task.decisionTime;
    elseif response(trialBlock) == 8888 % if missed trial
        pSelected = 1; % this trial won't contribute to logLikelihood (and isn't included in BIC num observations)
        tau = delay + task.decisionTime; % missed trials result in same timing as an accept trial
        response(trialBlock) = 0; % set response to 0 for logging reward
    end

    % get rid of non-finite values for pSelected before updating likelihood
    if pSelected == 0
        pSelected = eps(0);
    end

    logLikelihood = logLikelihood + log(pSelected); % update log likelihood

    % effort prediction error
    switch model.learnFunction
        case {'expected', 'expected_tau'}
            effortPE = E - bE;
        case {'exerted', 'exerted_tau'}
            if response(trialBlock) == 0 % if didn't accept
                effortPE = 0 - bE;
            elseif response(trialBlock) == 1
                effortPE = outcomeEffort(trialBlock) - bE;
            end            

        case {'reward', 'reward_tau'}
            if response(trialBlock) == 0 % if didn't accept
                rewardPE = 0 - bR;
            elseif response(trialBlock) == 1
                rewardPE = reward(trialBlock) - bR;
            end 
    end

    % log the data
    df = [df; trialTask, timeTask, trialBlock, timeBlock, cueEffort(trialBlock), SV, bE, bR, oppCost, pSelected, response(trialBlock), outcomeEffort(trialBlock), blockType(trialBlock), blockN, effortPE, rewardPE, reward(trialBlock)];

    % update background estimate
    switch model.learnFunction
        case {'expected', 'exerted'}
            bE = bE + alpha * effortPE;
        case 'expected_tau'
            bE = bE + alpha * effortPE; % update at cue onset
            for ii = 1:tau-1 
                bE = (1 - alpha) * bE;            
            end
        case 'exerted_tau'
            for ii = 1:tau-1 
                bE = (1 - alpha) * bE;
            end
            bE = bE + alpha * effortPE; % update at end of trial once effort exerted
        case 'reward'
            bR = bR + alpha * rewardPE;
        case 'reward_tau'
            for ii = 1:tau-1
                bR = (1 - alpha) * bR;
            end
            bR = bR + alpha * rewardPE;
    end

    % time passes
    timeTask = timeTask + tau;
    timeBlock = timeBlock + tau;

    %% prepare for next trial

    % next trial
    trialBlock = trialBlock + 1;
    trialTask = trialTask + 1;

    % when time or trials in block is finished, start new block
    if timeBlock >= task.blockTime || trialBlock > numel(response)
        % store this block's data and refresh df
        results{blockN} = array2table(df);
        results{blockN}.Properties.VariableNames = {'trialN', 'time', 'trialNinBlock', 'timeBlock', 'effortLevel', 'predictedValue', 'backgroundEffort', 'backgroundReward', 'oppCost', 'pSelected','response', 'realEffort', 'blockType', 'blockNumber', 'effortPE','rewardPE', 'reward'};
        
        % output in the format for recovery
        response_out{blockN}.response = results{blockN}.response;
        response_out{blockN}.cueEffort = results{blockN}.effortLevel;
        response_out{blockN}.outcomeEffort = results{blockN}.realEffort;
        response_out{blockN}.blockType = results{blockN}.blockType;
        response_out{blockN}.reward = results{blockN}.reward;

        df = [];

        blockN = blockN+1; % next block number
        if blockN > task.nBlocks % if on last block, end the simulation
            break
        end
        timeBlock = 1; % refresh time in block counter
        trialBlock = 1; % refresh trial in block counter

        % index into data for new block
        response = agent{blockN}.response;
        cueEffort = agent{blockN}.cueEffort;
        outcomeEffort = agent{blockN}.outcomeEffort;
        blockType = agent{blockN}.blockType;
        reward = agent{blockN}.reward;

    end
end
results = vertcat(results{:});
negLL = -logLikelihood; % negative log likelihood (NLL)

end