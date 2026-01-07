function [negLL, results, response_out] = simulate_AET_model(task,model,agent,agentParams)

% set up parameters
params = array2table(agentParams); params.Properties.VariableNames = model.paramNames;

beta = params.beta;
kOffer = params.kOffer; 

switch model.discountFunction
    case 'weight'
        weight = params.weight;
end

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
        bR = task.credits(1);
        alpha = params.alpha;
    case 'exerted'
        delay = 1;
        bE = task.effortLevels(1); %task.effortLevels(1); % start lower - most likely to accept lowest effort level
        bR = task.credits(1);
        alpha = params.alpha;
    case 'response_history'
        delay = 1;
        bE = task.effortLevels(2);
        bR = 0.5; % start equally likely to accept vs reject
        alpha = params.alpha;
    case 'fixed'
        delay = 1;
        bE = 0; 
        bR = 0; 
        oppCost_params = [params.oppCost_easy, params.oppCost_hard];

    % case {'expected_tau','exerted_tau', 'reward_tau'}
    %     delay = task.acceptTime;
    %     bE = task.effortLevels(2)/delay;
    %     bR = task.reward/delay;
    %     alpha = params.alpha;
end


R = task.credits(1);
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
        case {'expected', 'exerted', 'reward'}
            oppCost = (bR - bE) * delay; 
        case 'response_history'
            oppCost = bR;
        case 'fixed'

            if blockType(trialBlock) == 11
                oppCost = oppCost_params(1) + oppCost_params(2); % baseline + shift
            elseif blockType(trialBlock) == 99
                oppCost = oppCost_params(1); % baseline
            end
            %oppCost = oppCost_params(blockType(trialBlock) == task.env); 

    end

    switch model.discountFunction
        case 'weight'
            SV = (1-weight)*(R-kOffer*E^2) - weight*oppCost; % compute subjective value
        case 'none'
            SV = (R-kOffer*E^2) - oppCost; % compute subjective value
    end


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

    % prediction error
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
        case 'response_history'
            rewardPE = response(trialBlock) - bR;
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
                bE = (1 - alpha) * bE;  % E = 0 for timesteps in trial             
            end
        case 'exerted_tau'
            for ii = 1:tau-1 
                bE = (1 - alpha) * bE; % E = 0 for timesteps in trial
            end
            bE = bE + alpha * effortPE; % update at end of trial once effort exerted
        case {'reward', 'response_history'}
            bR = bR + alpha * rewardPE;
        case 'reward_tau'
            for ii = 1:tau-1
                bR = (1 - alpha) * bR;  % R = 0 for timesteps in trial
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