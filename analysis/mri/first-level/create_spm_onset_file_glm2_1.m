%% AET MRI analysis - script to prepare condition onset and pmod .mat files for SPM 1st-level design
% Emma Scholey
% 17 Dec 2024
clearvars; close all

cd(['~/Dropbox/average-effort/data_raw/mri/behaviour/main/']) % change as required
matFiles = dir('*MRI.mat');
matFiles = orderfields(matFiles);
model_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/sub-';

name_subj = [101:104, 106:110, 112:131, 133:141]; % The file (subject) numbers of the files to be used in the analysis

% exclude subjects
for i = 1:length(matFiles)
    ix(i) = ismember(str2double(matFiles(i).name(1:3)), name_subj);
end

matFiles = matFiles(ix);

for i = 1:length(matFiles)

    modelEstimates = readtable([model_dir, matFiles(i).name(2:3), '/model_estimates_M13_fit_MAP_v2.csv']);

    % load data
    load(matFiles(i).name);

    %% extract onsets for design matrix
    t1 = data.timelog.expStart;

    timelog = {data.timelog.block1,data.timelog.block2,data.timelog.block3,data.timelog.block4,data.timelog.block5,data.timelog.block6};
    timelog = vertcat(timelog{:});
    timelog(all(cellfun(@isempty, timelog),2),:) = []; % remove empty straggling rows

    cueIndex = find(strcmp(data.timelog.colnames,'offerOnset'));
    decisionIndex = find(strcmp(data.timelog.colnames,'decisionOnset'));
    exertIndex = find(strcmp(data.timelog.colnames,'exertOnset'));
    feedbackIndex = find(strcmp(data.timelog.colnames,'feedbackOnset'));
    missIndex = find(strcmp(data.timelog.colnames,'missedOnset'));

    cueOnsets = ([timelog{:,cueIndex}] - t1)';

    decisionOnsets = ([timelog{:,decisionIndex}] - t1)';

    exertOnsets = ([timelog{:,exertIndex}] - t1)';
    exertOnsets(isnan(exertOnsets)) = [];

    feedbackOnsets = ([timelog{:,feedbackIndex}] - t1)';
    feedbackOnsets(isnan(feedbackOnsets)) = [];

    missOnsets = ([timelog{:,missIndex}] - t1)';
    missOnsets(isnan(missOnsets)) = [];

    blockOnsets = data.timelog.blockOnsets - t1;
    breakOnsets = data.timelog.blockBreakOnsets - t1;

    %% Generate pmod based on model

    names={'cue' 'decision', 'exert' 'feedback' 'new_block' 'break'}; % create the names for each condition

    onsets=cell(1,length(names));

    pmod = struct('name',{''},'param',{},'poly',{});

    durations={0,0,0,0,5,10}; % specify the durations for each of the 3 conditions, since it is event related each duration is set to 0, new block screen shown for 5s, break of 10 seconds

    onsets{1} = [];
    onsets{2} = decisionOnsets;
    onsets{3} = exertOnsets;
    onsets{4} = feedbackOnsets;

    onsets{5} = blockOnsets;
    onsets{6} = breakOnsets;

    orth = {0, 0, 0, 0, 0, 0};


    %% Add missed onsets if applicable
    if ~isempty(missOnsets)% if miss trials, create another regressor
        names{7} = 'miss'; % create the names for each condition

        for j = 1:length(missOnsets)
            iMiss(j) = find(missOnsets(j) > cueOnsets, 1, "last"); % find cue onset with missed response
        end
        onsets{7} = cueOnsets(iMiss);
        durations{7} = 11; % time of a missed trial
        orth{7} = 0;

        % remove these trials from cue Onsets (assume participant ignored this cue)
        keepIdx = true(length(cueOnsets), 1); % init to true
        keepIdx(iMiss) = false;
        clear iMiss
    else
        keepIdx = true(length(cueOnsets), 1); % keep all cue onset (no missed trials)
    end

    onsets{1} = cueOnsets(keepIdx);

    %% Parametric modulators for cue
    pmod(1).name{1} = 'value';
    pmod(1).param{1} = zscore(modelEstimates.predictedValue(keepIdx));
    pmod(1).poly{1}=1;

    pmod(1).name{2} = 'backgroundEffort';
    pmod(1).param{2} = zscore(modelEstimates.backgroundEffort(keepIdx));
    pmod(1).poly{2}=1;

    tmp = abs(modelEstimates.effortPE);
    pmod(1).name{3} = 'unsigned_effortPE';
    pmod(1).param{3} = zscore(tmp(keepIdx));
    pmod(1).poly{3}=1;
    %% Parametric modulators for EXERT

    tmp = modelEstimates.realEffort(modelEstimates.response == 1);
    tmp = zscore(tmp);
    pmod(3).name{1} = 'effort_exerted';
    pmod(3).param{1} = tmp;
    pmod(3).poly{1}=1;

    %% Parametric modulators for FEEDBACK

    tmp = modelEstimates.reward(modelEstimates.response == 1);
    tmp = zscore(tmp);
    pmod(4).name{1} = 'reward';
    pmod(4).param{1} = tmp; % note this will also include failed trials
    pmod(4).poly{1}=1;

    save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M13_fit_MAP/glm2_1/sub-';
    mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

    subjectFolder = [save_onsets_dir, matFiles(i).name(2:3), '/'];
    save(fullfile(subjectFolder, 'conditions_onsets_pmod.mat'), 'names', 'onsets', 'durations', 'orth', 'pmod');
end

