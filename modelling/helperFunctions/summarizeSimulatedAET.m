function metrics = summarizeSimulatedAET(simdata, task)
% SUMMARIZESIMULATEDAET Compute aggregate measures from simulated AET trials.
%
% metrics = SUMMARIZESIMULATEDAET(simdata, task) takes the cell array of
% simulated trial tables returned by simulatedata() and produces summary
% statistics per effort level and environment as well as trial-wise
% trajectories for background effort and opportunity cost.
%
% Output fields:
%   metrics.acceptRate.raw        - [nSub x nEff x nEnv] acceptance rates
%   metrics.acceptRate.mean       - [nEff x nEnv] mean acceptance rate
%   metrics.offerValue.raw        - [nSub x nEff x nEnv] predicted value
%   metrics.offerValue.mean       - [nEff x nEnv]
%   metrics.background.raw        - [nSub x nEff x nEnv] background effort
%   metrics.background.mean       - [nEff x nEnv]
%   metrics.effortPE.raw          - [nSub x nEff x nEnv]
%   metrics.effortPE.mean         - [nEff x nEnv]
%   metrics.trajectories.time     - column vector of trial indices
%   metrics.trajectories.background - [nSub x nTrials] background effort
%   metrics.trajectories.oppCost    - [nSub x nTrials] opportunity cost
%
% Author: Emma Scholey, Nov 2025

arguments
    simdata (1, :) {mustBeA(simdata, 'cell')}
    task struct
end

nSubj = numel(simdata);
nEff = numel(task.effortLevels);
nEnv = numel(task.env);

acceptRate = nan(nSubj, nEff, nEnv);
offerValue = nan(nSubj, nEff, nEnv);
backgroundEffort = nan(nSubj, nEff, nEnv);
effortPE = nan(nSubj, nEff, nEnv);

trialCounts = cellfun(@(tbl) height(tbl), simdata);
maxTrials = max(trialCounts);
backgroundTraj = nan(nSubj, maxTrials);
oppCostTraj = nan(nSubj, maxTrials);

for iSub = 1:nSubj
    tbl = simdata{iSub};
    if isempty(tbl)
        continue
    end

    nTrials = height(tbl);
    backgroundTraj(iSub, 1:nTrials) = tbl.backgroundEffort;
    oppCostTraj(iSub, 1:nTrials) = tbl.oppCost;

    for iEnv = 1:nEnv
        envMask = tbl.blockType == task.env(iEnv);
        for iEff = 1:nEff
            effMask = tbl.effortLevel == task.effortLevels(iEff);
            mask = envMask & effMask & tbl.response ~= 8888;

            if any(mask)
                acceptRate(iSub, iEff, iEnv) = mean(tbl.response(mask), 'omitnan');
                offerValue(iSub, iEff, iEnv) = mean(tbl.predictedValue(mask), 'omitnan');
                backgroundEffort(iSub, iEff, iEnv) = mean(tbl.backgroundEffort(mask), 'omitnan');
                effortPE(iSub, iEff, iEnv) = mean(tbl.effortPE(mask), 'omitnan');
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

metrics.trajectories.time = (1:maxTrials)';
metrics.trajectories.background = backgroundTraj;
metrics.trajectories.oppCost = oppCostTraj;

end






