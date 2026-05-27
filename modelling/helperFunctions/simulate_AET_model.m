function [negLL, results, response_out] = simulate_AET_model(task,model,agent,agentParams)

% set up parameters
params = array2table(agentParams); params.Properties.VariableNames = model.paramNames;

beta = params.beta;
kOffer = params.kOffer;


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

% initialise decision variables
switch model.learnFunction
    case {'expected'}
        delay = 1;
        bE = task.effortLevels(2);
        bR = task.reward;
        alpha = params.alpha;

    case 'response_history'
        delay = 1;
        bE = 0;
        bR = 0.5; % start equally likely to accept vs reject
        alpha = params.alpha;

    case 'real'
        delay = 1;
        bR = task.reward;

end

R = task.reward;

effortPE = 0;
rewardPE = 0;

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

    switch model.learnFunction
        case {'expected'} 
            oppCost = - bE * delay;
        case 'response_history'
            oppCost = bR;
        case 'real'
            if blockType(trialBlock) == 11 % easy environment
                bE = task.real_bE(1);
            elseif blockType(trialBlock) == 99 % hard environment
                bE = task.real_bE(2);
            end

            oppCost = - bE * delay;

    end

    % calculate subjective value
    switch model.discountFunction
        case 'linear'
            SV = R - (kOffer * E^2) - oppCost;
    end


    pAccept = softmaxAccept(beta, SV, 0,0); % comparator term will be 0 if oppCost already weighting value

    if isnan(response(trialBlock)) % if simulating data
        response(trialBlock) = (rand(1) < pAccept);     % make a choice of next action
    end

    % log the probability of selected action
    if response(trialBlock) == 1 % if subject accepted
        pSelected = pAccept;
        tau = task.acceptTime + task.decisionTime;
    elseif response(trialBlock) == 0 % if subject rejected
        pSelected = 1-pAccept;
        tau = task.rejectTime + task.decisionTime;
    elseif response(trialBlock) == 8888 % if missed trial
        pSelected = 1; % this trial won't contribute to logLikelihood (and isn't included in BIC num observations)
        tau = task.acceptTime + task.decisionTime; % missed trials result in same timing as an accept trial
        response(trialBlock) = 0; % set response to 0 for logging reward
    end

    % get rid of non-finite values for pSelected before updating likelihood
    if pSelected == 0
        pSelected = eps(0);
    end

    logLikelihood = logLikelihood + log(pSelected); % update log likelihood

    % prediction error
    switch model.learnFunction
        case 'expected'
            effortPE = E - bE;
        case 'response_history'
            rewardPE = response(trialBlock) - bR;
    end

    % log the data
    df = [df; trialTask, timeTask, trialBlock, timeBlock, cueEffort(trialBlock), SV, bE, bR, oppCost, pSelected, response(trialBlock), outcomeEffort(trialBlock), blockType(trialBlock), blockN, effortPE, rewardPE, reward(trialBlock)];

    % update background estimate
    switch model.learnFunction
        case 'expected'
            bE = bE + alpha * effortPE;
        case {'response_history'}
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