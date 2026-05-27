function [metrics, out] = summarise_simulated(simdata, config)
% Compute aggregate measures from simulated AET trials.

% Author: Emma Scholey, Nov 2025

arguments
    simdata (1, :) {mustBeA(simdata, 'cell')}
    config struct
end

nSubj = numel(simdata);
nEff = numel(config.task.effortLevels);
nEnv = numel(config.task.env);

%% Prepare for R plotting/statistics
for iSub = 1:nSubj
    tbl = simdata{iSub};
    if isempty(tbl), continue; end

    % assign subject number
    tbl.subjectNumber = repmat(iSub, height(tbl), 1);

    % response history (whether they accept/reject on previous trial)
    tbl.responseHistory = zeros(height(tbl), 1);
    tbl{2:end, 'responseHistory'} = tbl{1:end-1, 'response'};
    tbl{tbl.trialNinBlock == 1, 'responseHistory'} = 0;

    % effort history (what effort they saw on the previous trial)
    tbl.effortHistory = repmat(2, height(tbl), 1);
    tbl{2:end, 'effortHistory'} = tbl{1:end-1, 'effortLevel'};
    tbl{tbl.trialNinBlock == 1, 'effortHistory'} = 2;

    % average effort history (moving window of previous 5 trials)
    tbl.averageEffortRate_4 = repmat(2, height(tbl), 1);
    tbl{2:end, 'averageEffortRate_4'} = movmean(tbl{1:end-1, 'effortHistory'}, [4,0]);
    tbl{tbl.trialNinBlock == 1, 'effortHistory'} = 2;


    % % exerted effort history (what effort they exerted on the previous trial)
    % tbl.exertedEffortHistory = zeros(height(tbl), 1);
    % tbl{2:end, 'exertedEffortHistory'} = tbl{1:end-1, 'realEffort'};
    % tbl{tbl.trialNinBlock == 1, 'exertedEffortHistory'} = 0;


    simdata{iSub} = tbl;
end
out = vertcat(simdata{:});

%% Summarise simulated results
acceptRate = nan(nSubj, nEff, nEnv);
offerValue = nan(nSubj, nEff, nEnv);
backgroundEffort = nan(nSubj, nEff, nEnv);
effortPE = nan(nSubj, nEff, nEnv);

trialCounts = cellfun(@(tbl) height(tbl), simdata);
maxTrials = max(trialCounts);
backgroundTraj = nan(nSubj, maxTrials);
oppCostTraj = nan(nSubj, maxTrials);
backgroundRewTraj = nan(nSubj, maxTrials);

for iSub = 1:nSubj
    tbl = simdata{iSub};
    if isempty(tbl)
        continue
    end

    nTrials = height(tbl);
    backgroundTraj(iSub, 1:nTrials) = tbl.backgroundEffort;
    backgroundRewTraj(iSub, 1:nTrials) = tbl.backgroundReward;
    oppCostTraj(iSub, 1:nTrials) = tbl.oppCost;

    for iEnv = 1:nEnv
        envMask = tbl.blockType == config.task.env(iEnv);
        for iEff = 1:nEff
            effMask = tbl.effortLevel == config.task.effortLevels(iEff);
            mask = envMask & effMask & tbl.response ~= 8888;

            if any(mask)
                acceptRate(iSub, iEff, iEnv) = mean(tbl.response(mask), 'omitnan');
                offerValue(iSub, iEff, iEnv) = mean(tbl.predictedValue(mask), 'omitnan');
                backgroundEffort(iSub, iEff, iEnv) = mean(tbl.backgroundEffort(mask), 'omitnan');
                effortPE(iSub, iEff, iEnv) = mean(tbl.effortPE(mask), 'omitnan');
                rewardPE(iSub, iEff, iEnv) = mean(tbl.rewardPE(mask), 'omitnan');
                backgroundReward(iSub, iEff, iEnv) = mean(tbl.backgroundReward(mask), 'omitnan');

            end
        end
    end
end

metrics = struct();
metrics.acceptRate.raw = acceptRate;
metrics.acceptRate.mean = squeeze(mean(acceptRate, 1, 'omitnan'));

metrics.offerValue.raw = offerValue;
metrics.offerValue.mean = squeeze(mean(offerValue, 1, 'omitnan'));

metrics.background.raw = backgroundEffort;
metrics.background.mean = squeeze(mean(backgroundEffort, 1, 'omitnan'));

metrics.effortPE.raw = effortPE;
metrics.effortPE.mean = squeeze(mean(effortPE, 1, 'omitnan'));

metrics.rewardPE.raw = rewardPE;
metrics.rewardPE.mean = squeeze(mean(rewardPE, 1, 'omitnan'));

metrics.backgroundRew.raw = backgroundReward;
metrics.backgroundRew.mean = squeeze(mean(backgroundReward, 1, 'omitnan'));

metrics.trajectories.time = (1:maxTrials)';
metrics.trajectories.background = backgroundTraj;
metrics.trajectories.backgroundRew = backgroundRewTraj;
metrics.trajectories.oppCost = oppCostTraj;


end

