function [negLL, out] = simulate_AET_task(task,model,agent,agentParams)

% convert parameter array to table to allow indexing
params = array2table(agentParams); params.Properties.VariableNames = model.paramNames;

% set up trial counters
trialTask = 1; % start trials in task counter
trialBlock = 1; % start trials in block counter
timeTask = 0; % start time in task counter
timeBlock = 0; % start time in block counter

blockN = 1; % start in first block

% start with data from first block
response = agent.data{blockN}(:,1); % if accepted (1) or waited (0)
cueEffort = agent.data{blockN}(:,2); % either shape cue (v1), or effort level (v3 and mri)
outcomeEffort = agent.data{blockN}(:,3); % this will only differ to cueEffort for v1, since probabilistic cue
blockType = agent.data{blockN}(:,4); % environment type: 11 = easy, 99 = hard
reward = agent.data{blockN}(:,5);

% initialise decision variables, we should rescale the opportunity cost:
% the value/effort rate per timestep, multiplied by
% time taken to accept a trial

if strcmp(model.discountFunction, 'effort')
    tau_weight = 1;
else
    tau_weight = task.acceptTime;
end

bE = task.effortLevels(2)/tau_weight; % background effort rate
bR = task.reward/tau_weight; % background reward rate 


bV = 0; % background value (reward discounted by effort)
oppCost = 0; % opp cost, taking into account pursue time (task.acceptTime)
effortPE = 0;

% specify subject learning rate
switch model.discountFunction
    case {'effort', 'effort_adaptive', 'effort_opp_cost', 'reward', 'exert_opp_cost', 'effort_test'}
        alpha = params.alpha;
end
% set beta
switch model.numBeta
    case 'one'
        beta = params.beta_one;
    case 'two'
        if agent.data{blockN}(1,4) == 11 % easy
            beta = params.beta_one;
        elseif agent.data{blockN}(1,4) == 99 % hard
            beta = params.beta_two;
        end        
end
% specify background discount parameter
switch model.numK
    case 'one'
        kOffer = params.kOffer; % effort discount parameter
    case 'two'
        kOffer = params.kOffer; % effort discount parameter
        k = params.k; % allow separate k's for offer and background
end

logLikelihood = 0; % for model fitting

df = []; % create empty container to store timestep results

while blockN <= task.nBlocks

    % t = 0 in trial
    %% see the effort cue, and make a decision
    
    E = cueEffort(trialBlock);

    if strcmp(model.discountFunction, 'prev_eff')
        if  trialBlock == 1
            prev_eff = 0;
        else
            prev_eff = cueEffort(trialBlock-1);
        end
    end

    % refresh R each trial
    if strcmp(model.discountFunction, 'reward')
        R = task.medianReward; % take actual most likely reward value from the task (differs for each study)
    else
        R = task.reward; % fix reward to 2, equivalent to effort level 2
    end

    % compute subjective value, SV
    switch model.discountFunction
        case 'reward'
            SV = R;
            bV = bR;
        case {'effort_opp_cost', 'effort', 'exert_opp_cost'}
            switch model.numK
                case 'one'
                    SV = R - (kOffer * E^2) + (kOffer*(bE*tau_weight));
                case 'two'
                    SV = R - (kOffer * E^2) + (k*bE*tau_weight);
            end
        case 'prev_eff'
            switch model.numK
                case 'one'
                    SV = R - (kOffer * E^2) + kOffer*prev_eff;
                case 'two'
                    SV = R - (kOffer * E^2) + k*prev_eff;
            end    
        case {'effort_adaptive'}
            switch model.numK
                case 'one'
                SV = R - kOffer * ((E^2-kOffer*bE*tau_weight)/(bE*tau_weight));  % relative coding (Weber's law) - definitely not this model! 
                    %SV = R - kOffer * (E^2/(1+bE*tau_weight));  % divisive normalisation
                case 'two'
            end
        case 'effort_test'
            switch model.numK
                case 'one'
                    SV = R - (kOffer * E^2) + (kOffer*((bE*tau_weight)^2));
                case 'two'
                    SV = R - (kOffer * E^2) + (k*((bE*tau_weight)^2));
            end
    end

    oppCost = bV*tau_weight;
    pAccept = softmaxAccept(beta, SV, oppCost); % oppCost will be 0 if backgroundEffort already weighting value

    if isnan(response(trialBlock)) % if simulating data
        response(trialBlock) = (rand(1) < pAccept);     % make a choice of next action
    end

    % log the probability of selected action
    if response(trialBlock) == 1 % if subject accepted
        pSelected = pAccept;
        tau = task.acceptTime + task.decisionTime;
    elseif response(trialBlock) == 0 % if subject rejected
        R = 0;
        pSelected = 1-pAccept;
        tau = task.rejectTime + task.decisionTime;
    elseif response(trialBlock) == 8888 % if missed trial
        R = 0;
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
    switch model.discountFunction
        case 'effort_opp_cost'
            effortPE = E/tau - bE;
        case 'effort'
            effortPE = E - bE;
        case 'reward'
            rewardPE = R/tau - bR;
        case 'exert_opp_cost'  %% TO REMOVE - simulations cannot capture mid effort behaviour - it just explains people who don't show any effect better. 
            EX =  response(trialBlock) * outcomeEffort(trialBlock);
            effortPE = EX/tau - bE;            
        case 'effort_test'
            effortPE = E/task.acceptTime - bE;
    end

    % log the data
    df = [df; trialTask, timeTask, trialBlock, timeBlock, cueEffort(trialBlock), SV, bE, bV, oppCost, pSelected, response(trialBlock), outcomeEffort(trialBlock), blockType(trialBlock), blockN, effortPE, reward(trialBlock)];

    % update background
    switch model.discountFunction
        case 'effort_opp_cost'
            bE = bE + (1-(1-alpha)^tau) * effortPE;
        case 'effort'
            bE = bE + (1-(1-alpha)) * effortPE;
        case 'reward'
            bR = bR + (1-(1-alpha)^tau) * rewardPE;
        case 'exert_opp_cost'
            bE = bE + (1-(1-alpha)^tau) * effortPE;
        case 'effort_test'
            bE = bE + (1-(1-alpha)^tau) * effortPE;
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
        blockN = blockN+1; % next block number
        if blockN > task.nBlocks % if on last block, end the simulation
            break
        end
        timeBlock = 1; % refresh time in block counter
        trialBlock = 1; % refresh trial in block counter

        % index into data for new block
        response = agent.data{blockN}(:,1);
        cueEffort = agent.data{blockN}(:,2);
        outcomeEffort = agent.data{blockN}(:,3);
        blockType = agent.data{blockN}(:,4);
        reward = agent.data{blockN}(:,5);

        % set beta
        if strcmp(model.numBeta, 'two')
            if agent.data{blockN}(1,4) == 11 % easy
                beta = params.beta_one;
            elseif agent.data{blockN}(1,4) == 99 % hard
                beta = params.beta_two;
            end
        end

    end
end

negLL = -logLikelihood; % negative log likelihood (NLL)

% log timestep data
out = array2table(df);
out.Properties.VariableNames = {'trialN', 'time', 'trialNinBlock', 'timeBlock', 'effortLevel', 'predictedValue', 'backgroundEffort', 'backgroundValue', 'oppCost', 'pSelected','response', 'realEffort', 'blockType', 'blockNumber', 'effortPE', 'reward'};

end