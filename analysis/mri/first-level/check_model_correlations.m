
close all, clear all
data_folder = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/sub-'; %where your multiple conditions .mat file is

%%% Subject IDs
name_subj = [1:4, 6:10, 12:31, 33:41];% the names of all of your subjects that you have onsets for

figure, tl = tiledlayout('flow');

%% Correlations
% for s = 1:15 %length(name_subj)
%     id = num2str(name_subj(s), '%02d');
%     display(id)
%     T = readtable([data_folder, id, '/model_estimates_z_score_M1.csv']);
%     %trial_filter = T.trialNinBlock < 11;
%     trial_filter = T.effortLevel == 2;
%     trial_filter = T.effortLevel == 2 && T.response == 0; % rejected mid effort trials
% 
%     %subj_corr(s) = corr(T.predictedValue(trial_filter),T.effortPE(trial_filter));
% 
%     count 
%     nexttile
%     plot(T.trialN(trial_filter), T.predictedValue(trial_filter)), hold on
%     plot(T.trialN(trial_filter), T.effortPE(trial_filter))
%     title(id)
% 
% end
% 
% mean_corr = mean(subj_corr);

%% trial counts
for s = 1:length(name_subj)
    id = num2str(name_subj(s), '%02d');
    display(id)
    T = readtable([data_folder, id, '/model_estimates_M1.csv']);

    trial_filter = (T.effortLevel == 2 | T.effortLevel == 3) & T.response == 0; % rejected mid effort trials

    %subj_corr(s) = corr(T.predictedValue(trial_filter),T.effortPE(trial_filter));

    n_trials_rejected(s) = sum(trial_filter);
    n_trials_accepted(s) = sum(~trial_filter);

end
    
mean_trials_accepted = mean(n_trials_accepted);
mean_trials_rejected = mean(n_trials_rejected);


