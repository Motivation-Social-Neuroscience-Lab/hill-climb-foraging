%% AET MRI analysis - script to prepare condition onset and pmod .mat files for SPM 1st-level design
% Emma Scholey
% 17 Dec 2024
% create condition onset and pmod files for glm 1 - test parametric modulators separately
clearvars; close all

all_modulator = {'value', 'effort', 'backgroundEffort', 'effortPE', 'unsigned_effortPE'};

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

    modelEstimates = readtable([model_dir, matFiles(i).name(2:3), '/model_estimates_M1.csv']);

    % load data
    load(matFiles(i).name);

    %% extract onsets for design matrix
    t1 = data.timelog.expStart;

    timelog = {data.timelog.block1,data.timelog.block2,data.timelog.block3,data.timelog.block4,data.timelog.block5,data.timelog.block6};
    timelog = vertcat(timelog{:});
    timelog(all(cellfun(@isempty, timelog),2),:) = []; % remove empty straggling rows

    cueIndex = find(strcmp(data.timelog.colnames,'offerOnset'));
    %decisionIndex = find(strcmp(data.timelog.colnames,'decisionOnset'));
    exertIndex = find(strcmp(data.timelog.colnames,'exertOnset'));
    feedbackIndex = find(strcmp(data.timelog.colnames,'feedbackOnset'));
    missIndex = find(strcmp(data.timelog.colnames,'missedOnset'));

    cueOnsets = ([timelog{:,cueIndex}] - t1)';

    %decisionOnsets = ([timelog{:,decisionIndex}] - t1)';

    exertOnsets = ([timelog{:,exertIndex}] - t1)';
    exertOnsets(isnan(exertOnsets)) = [];

    feedbackOnsets = ([timelog{:,feedbackIndex}] - t1)';
    feedbackOnsets(isnan(feedbackOnsets)) = [];

    missOnsets = ([timelog{:,missIndex}] - t1)';
    missOnsets(isnan(missOnsets)) = [];

    blockOnsets = data.timelog.blockOnsets - t1;
    breakOnsets = data.timelog.blockBreakOnsets - t1;

    %% Generate pmod based on model

    names={'cue' 'exert' 'feedback' 'new_block' 'break'}; % create the names for each condition

    onsets=cell(1,5);

    pmod = struct('name',{''},'param',{},'poly',{});

    durations={0,0,0,5,10}; % specify the durations for each of the 3 conditions, since it is event related each duration is set to 0, new block screen shown for 5s, break of 10 seconds

    onsets{1} = []; % will be cue onsets - but deal with missed trials first
    onsets{2} = exertOnsets;
    onsets{3} = feedbackOnsets;

    onsets{4} = blockOnsets;
    onsets{5} = breakOnsets;

    orth = {0, 0, 0, 0, 0};

    %% Add missed onsets if applicable
    if ~isempty(missOnsets)% if miss trials, create another regressor
        names{6} = 'miss'; % create the names for each condition

        for j = 1:length(missOnsets)
            iMiss(j) = find(missOnsets(j) > cueOnsets, 1, "last"); % find cue onset with missed response
        end
        onsets{6} = cueOnsets(iMiss);
        durations{6} = 11; % time of a missed trial
        orth{6} = 0;

        % remove these trials from cue Onsets (assume participant ignored this cue)
        keepIdx = true(length(cueOnsets), 1); % init to true
        keepIdx(iMiss) = false;
        clear iMiss
    else
        keepIdx = true(length(cueOnsets), 1); % keep all cue onset (no missed trials)
    end

    onsets{1} = cueOnsets(keepIdx);

    %% Parametric modulators for cue
    for m = 1:length(all_modulator)
        m
        modulator = all_modulator{m};
        switch modulator
            case 'value'

                save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1/glm1_1/sub-';
                mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

                pmod(1).name{1} = 'value';
                pmod(1).param{1} = zscore(modelEstimates.predictedValue(keepIdx));
                pmod(1).poly{1}=1;

            case 'effort'

                save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1/glm1_2/sub-';
                mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

                pmod(1).name{1} = 'effort';
                pmod(1).param{1} = zscore(modelEstimates.effortLevel(keepIdx));
                pmod(1).poly{1}=1;


            case 'backgroundEffort'

                save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1/glm1_3/sub-';
                mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

                pmod(1).name{1} = 'backgroundEffort';
                pmod(1).param{1} = zscore(modelEstimates.backgroundEffort(keepIdx));
                pmod(1).poly{1}=1;

            case 'effortPE'

                save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1/glm1_4/sub-';
                mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

                pmod(1).name{1} = 'effortPE';
                pmod(1).param{1} = zscore(modelEstimates.effortPE(keepIdx));
                pmod(1).poly{1}=1;

            case 'unsigned_effortPE'

                save_onsets_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1/glm1_5/sub-';
                mkdir([save_onsets_dir,matFiles(i).name(2:3)]);

                tmp = abs(modelEstimates.effortPE);

                pmod(1).name{1} = 'unsigned_effortPE';
                pmod(1).param{1} = zscore(tmp(keepIdx));
                pmod(1).poly{1}=1;

        end

        %% Parametric modulators for EXERT

        tmp = modelEstimates.realEffort(modelEstimates.response == 1);
        tmp = zscore(tmp);
        pmod(2).name{1} = 'effort_exerted';
        pmod(2).param{1} = tmp;
        pmod(2).poly{1}=1;

        %% Parametric modulators for FEEDBACK

        tmp = modelEstimates.reward(modelEstimates.response == 1);
        tmp = zscore(tmp);
        pmod(3).name{1} = 'reward';
        pmod(3).param{1} = tmp; % note this will also include failed trials
        pmod(3).poly{1}=1;

        subjectFolder = [save_onsets_dir, matFiles(i).name(2:3), '/'];
        save(fullfile(subjectFolder, 'conditions_onsets_pmod.mat'), 'names', 'onsets', 'durations', 'orth', 'pmod');

    end
end

