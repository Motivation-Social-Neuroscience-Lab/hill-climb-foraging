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
out = vertcat(vertcat(simdata{:}));
% add response history (whether they accept/reject on previous trial)
out{2:end, 'responseHistory'} = out{1:end-1, 'response'};
out{out.trialNinBlock == 1, 'responseHistory'} = 0;

% add effort history (what effort they exerted on the previous trial)
out{2:end, 'exertedEffortHistory'} = out{1:end-1,'realEffort'};
out{out.trialNinBlock == 1, 'exertedEffortHistory'} = 0;

% add effort history (what effort they saw on the previous trial)
out{2:end, 'effortHistory'} = out{1:end-1,'effortLevel'};
out{out.trialNinBlock == 1, 'effortHistory'} = 2;

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

