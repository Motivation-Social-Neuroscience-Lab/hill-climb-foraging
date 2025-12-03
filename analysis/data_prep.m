%%% Prepare AET data for analysis
%%% Created 10/10/19 (P. Lockwood & L Priestley)
%%% Modified 21/02/23 (Emma Scholey) for average effort experiment
%%% Modified 16/07/2024 (Emma Scholey) to work across all task versions 
clc
clear all

task_version = 'mri';

if strcmp(task_version, 'mri')
    cd(['~/Dropbox/average-effort/data_raw/' task_version '/behaviour/main/']) % change as required
    matFiles = dir('*MRI.mat');
else
    cd(['~/Dropbox/average-effort/data_raw/', task_version]) % change as required
    matFiles = dir('*.mat');
end

matFiles = orderfields(matFiles);

for i = 1:length(matFiles)

    % load data
    eval(['load ' matFiles(i).name]);

    % get colnames
    colnames = data.behav.colnames;
    colnames{2} = 'effort';
    colnames{3} = 'effortLevel';
    % Get pre-test MVC
    MVC(i) = ex.MVC;

    % Get post-test MVC
    if ~isfield(data, 'post_test_MVC') % if post test MVC doesn't exist
        data.post_test_MVC{1} = NaN;
    end
    postMVC(i) = data.post_test_MVC{1};

    % concatenate blocks
    behav = struct2cell(data.behav);
    behav = behav(find(strncmp('block',fields(data.behav),5))); % find main block data
    blockNums = 1:length(behav); % find how many blocks they did
    behav = vertcat(behav{:});
    behav(all(cellfun(@isempty, behav),2),:) = []; % remove empty straggling rows

    blockEndI = find(cell2mat(behav(2:end,1)) == 1); % find row numbers where block ends
    blockEndT = behav(blockEndI, 1); % find how many trials in each block
    blockEndT = [blockEndT; behav{end,1}]; % append on the final block
    behav(:,end+1) = num2cell(repelem(blockNums, cell2mat(blockEndT))); % add block number to data
    colnames{1,end+1} = 'blockNumber';

    % Add overall trialN
    behav(:,end+1) = num2cell(1:length(behav));
    colnames{1,end+1} = 'trialN';
    colnames{1,1} = 'trialNinBlock';

    for j = 1:length(behav)
        if ~isempty(behav{j,strcmp(colnames,'forceData')})
            behav{j,strcmp(colnames,'forceData')} = trapz(behav{j,strcmp(colnames,'forceData')}(:,1)); % trapezoidal numerical integration (approximation of integral)
        else
            behav{j,strcmp(colnames,'forceData')} = NaN;
        end
    end

    % standardise trial-by-trial force production
    %force_auc = nannormalise(cell2mat(behav(:, 10))); %couldn’t find nannormalise function. Will scale by max force and keep NaNs for now
    force_auc = cell2mat(behav(:, strcmp(colnames,'forceData')));
    force_auc = (force_auc - min(force_auc)) / (max(force_auc) - min(force_auc)); %normalise between 0-1 each trial based on max force provided across trials (keeps NaNs for now...)
    behav(:, strcmp(colnames,'forceData')) = num2cell(force_auc); 

    % recode high effort (99) and low effort (11) as numeric

    if strcmp(task_version, 'v1')
        for j = 1:length(behav)
            if strcmp(behav{j,strcmp(colnames,'blockType')}, 'high effort')
                behav{j,strcmp(colnames,'blockType')} = 99;
            elseif strcmp(behav{j,strcmp(colnames,'blockType')}, 'low effort')
                behav{j,strcmp(colnames,'blockType')} = 11;
            end
        end
    elseif ismember(task_version, {'v3', 'mri'})
        for j = 1:length(behav)
            if strcmp(behav{j,strcmp(colnames,'blockType')}, 'hard')
                behav{j,strcmp(colnames,'blockType')} = 99;
            elseif strcmp(behav{j,strcmp(colnames,'blockType')}, 'easy')
                behav{j,strcmp(colnames,'blockType')} = 11;
            end
        end
    end

    % change from cell2mat
    isEm = cellfun(@isempty, behav); % replace empty cells with NaN
    behav(isEm) = {NaN};
    behav = cell2mat(behav);

    % add response history (whether they accept/reject on previous trial)
    behav(2:end, end+1) = behav(1:end-1, strcmp(colnames,'response'));
    behav(1, end) = 0;
    behav(behav(:, end)==8888,end) = 0; % if missed last trial, treat as rejected
    colnames{1,end+1} = 'responseHistory';

    % add effort history (whether they exerted effort on the previous trial)
    if strcmp(task_version, 'v1')
        behav(2:end, end+1) = behav(2:end,strcmp(colnames,'responseHistory')) .* behav(1:end-1,strcmp(colnames,'realEffort'));
    elseif ismember(task_version, {'v3','mri'})
        behav(2:end, end+1) = behav(2:end,strcmp(colnames,'responseHistory')) .* behav(1:end-1,strcmp(colnames,'effortLevel'));
    end
    behav(1, end) = 0;
    colnames{1,end+1} = 'exertedEffortHistory';

    % add expected effort (what kind of shape they saw on the previous trial)
    behav(2:end, end+1) = behav(1:end-1,strcmp(colnames,'effortLevel'));
    behav(1, end) = 0.4; % just set as mid level for first trial
    colnames{1,end+1} = 'effortHistory';

    % add reward history (how many credits they received on previous trial)
    behav(2:end, end+1) = behav(1:end-1,strcmp(colnames,'reward'));
    behav(1, end) = 0;
    colnames{1,end+1} = 'rewardHistory';

   % add moving average of reward rate. Refreshed every new block
    behav(:,end+1) = zeros(1, length(behav));
    for iB = 1:6 
        which_trials = behav(:,strcmp(colnames,'blockNumber'))==iB;
        behav(which_trials,end) = movmean(behav(which_trials,strcmp(colnames,'rewardHistory')), [4 0]);
    end
    colnames{1,end+1} = 'averageRewardRate';

    % add moving average of effort rate. Refreshed every new block
    for iT = 1:7
            behav(:,end+1) = zeros(1, length(behav));
        for iB = 1:6
            which_trials = behav(:,strcmp(colnames,'blockNumber'))==iB;
            behav(which_trials,end) = movmean(behav(which_trials,strcmp(colnames,'effortHistory')), [iT 0]);
        end
        colnames{1,end+1} = ['averageEffortRate_', num2str(iT)];
    end

    if strcmp(task_version,'v1')
        % add real effort history (regardless of whether accepted/rejected)
        behav(2:end, end+1) = behav(1:end-1,strcmp(colnames,'realEffort'));
        behav(1, end) = 0.4;
        colnames{1,end+1} = 'realEffortHistory';
    end

    % add average exertion rate
    behav(:,end+1) = zeros(1, length(behav));
    for iB = 1:6
        which_trials = behav(:,strcmp(colnames,'blockNumber'))==iB;
        behav(which_trials,end) = movmean(behav(which_trials,strcmp(colnames,'exertedEffortHistory')), [4 0]);
    end
    colnames{1,end+1} = 'averageExertedRate';

    % add subject number
    sNumber = i*ones(length(behav),1);
    behav = [sNumber behav];
    colnames = ['subjectNumber' colnames];

    results{i} = array2table(behav);
    results{i}.Properties.VariableNames = colnames;

    blockOrder(i,:) = ex.blockOrder;

end

save(['~/Dropbox/average-effort/code/data/behavioural/', task_version '/blockOrder_' task_version '.mat'], 'blockOrder')

save(['~/Dropbox/average-effort/code/data/behavioural/', task_version '/behav_summary_' task_version '.mat'], 'results')

%% write behavioural results
results = vertcat(results{:});

filename = ['~/Dropbox/average-effort/code/data/behavioural/' task_version '/behav_summary_' task_version '.csv'];

writetable(results, filename)

%% write MVC comparison

mvc(:, 1) = MVC';
mvc(:, 2) = postMVC';

mvc = array2table(mvc);
filename = ['~/Dropbox/average-effort/code/data/behavioural/' task_version '/mvc_summary_' task_version '.csv'];

writetable(mvc, filename);


