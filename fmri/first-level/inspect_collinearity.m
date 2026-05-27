
close all, clear all
data_folder = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/first_level/z_6m_csf_wm_compcor_M1_fit_MAP_v2/glm2_1_excl/sub-'; %where your multiple conditions .mat file is

%data_folder = '/Users/exs165/Dropbox/average-effort/data_derived/mri/1st-level/glm1/sub-'; %where your multiple conditions .mat file is

%%% Subject IDs
name_subj = [1,2,4, 7:10, 12:31, 33:38, 40:41];% the names of all of your subjects that you have onsets for

figure, tl = tiledlayout('flow');
cond = {'cue onset', 'value', 'background', 'effortPE'};
cond_index = [1:4];


for s = 1:length(name_subj)
    id = num2str(name_subj(s), '%02d');
    display(id)
    load([data_folder, id, '/SPM.mat'])

    corr_matrix(:,:,s) = corr(SPM.xX.X(:,cond_index));

    nexttile
    heatmap(triu(abs(round(corr_matrix(:,:,s),2))), "ColorbarVisible","off")
    title(id)

    h.XDisplayLabels = cond;
    h.YDisplayLabels = cond;

end

% plot average correlation matrix

avg_corr_matrix = mean(corr_matrix,3)

figure
h = heatmap(triu(abs(round(avg_corr_matrix,2))), "ColorbarVisible","off")
h.XDisplayLabels = cond;
h.YDisplayLabels = cond;
set(gca, 'FontSize', 16)
