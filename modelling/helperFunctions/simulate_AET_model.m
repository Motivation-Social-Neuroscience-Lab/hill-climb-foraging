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

% for initialising bE and bR, assume reward/effort for start trial if
% accepted

if strcmp(model.learnFunction, 'expected')
    tau_weight = 1;
    bE = task.effortLevels(2); 
    bR = task.reward;
else
    tau_weight = task.acceptTime + task.decisionTime;
    bE = task.effortLevels(2)/tau_weight;
    bR = task.reward/tau_weight; % background reward rate

end

switch model.discountFunction
    case {'weight'}
        weight = params.weight;
end

R = task.reward; % fix reward to 2, equivalent to effort level 2

bV = 0; % background value (reward discounted by effort)
oppCost = 0; % opp cost, taking into account pursue time (task.acceptTime)
effortPE = 0; % no PE on first trial 

alpha = params.alpha;
beta = params.beta;
kOffer = params.kOffer; 

logLikelihood = 0; % for model fitting

df = []; % create empty container to store timestep results
results = cell(1,task.nBlocks);
response_out = cell(1,task.nBlocks);

while blockN <= task.nBlocks

    % t = 0 in trial
    %% see the effort cue, and make a decision
    
    E = cueEffort(trialBlock);

    switch model.discountFunction
        case 'additive'
            oppCost = bR*tau_weight - kOffer*(bE*tau_weight); % convert bR and bE into trial values rather than timestep
            SV = R - (kOffer * E^2) - oppCost; % as background value increases, current offer is less valuable

        case 'weight'
            oppCost = bR*tau_weight - bE*tau_weight;
            SV = (1-weight)*(R-kOffer*E^2) - weight*(oppCost);

        case 'additive_original'
            oppCost = - kOffer*(bE*tau_weight); % convert bR and bE into trial values rather than timestep
            SV = R - (kOffer * E^2) - oppCost; % as background value increases, current offer is less valuable

    end
    

    % compute subjective value, SV

    pAccept = softmaxAccept(beta, SV, 0); % oppCost will be 0 if backgroundEffort already weighting value

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

    % effort PE
    switch model.learnFunction
        case 'expected'
            effortPE = E - bE;
        case 'exerted'
            if response(trialBlock) == 0 % if didn't accept 
                effortPE = 0 - bE;
            elseif response(trialBlock) == 1
                effortPE = outcomeEffort(trialBlock) - bE;
            end
        case 'expected_tau'
            effortPE = E/tau - bE; 
    end

    % log the data
    df = [df; trialTask, timeTask, trialBlock, timeBlock, cueEffort(trialBlock), SV, bE, bV, oppCost, pSelected, response(trialBlock), outcomeEffort(trialBlock), blockType(trialBlock), blockN, effortPE, reward(trialBlock)];

    % update background
    switch model.learnFunction
        case 'exerted'
            for ii = 1:(tau - 1)
                bE = bE + alpha * (0-bE); % for all other timesteps, no effort
            end
            bE = bE + alpha * effortPE; % for final timestep, finished exerted effort (map onto Garrett's background reward model timings)
        case 'expected'
            bE = bE + alpha * effortPE; % singular prediction error at cue onset
        case 'expected_tau'
            bE = bE + (1-(1-alpha)^tau) * effortPE; % expected effort smooshed across the trial
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
        results{blockN}.Properties.VariableNames = {'trialN', 'time', 'trialNinBlock', 'timeBlock', 'effortLevel', 'predictedValue', 'backgroundEffort', 'backgroundValue', 'oppCost', 'pSelected','response', 'realEffort', 'blockType', 'blockNumber', 'effortPE', 'reward'};
        
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