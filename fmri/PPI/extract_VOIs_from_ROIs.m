%% Extract VOI from anatomically defined ROIs
% Requires first-level GLM SPM.mat file for each subject, and ROI.nii files

clear all 

addpath '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

data_folder = '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

% sphere masks
roi_files  = {
    '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_R_9m_effortPE_+7_+58_+25.nii'
    '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_R_RCZp_background_+10_-7_+42.nii'
    '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_bilateral_insula_value.nii'
    '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_bilateral_putamen_background.nii'
};

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
excl_subj = [3,6,39];
subj = setdiff(subj,excl_subj);

for s = 1:numel(subj)
    id = num2str(subj(s), '%02d');
    path = [data_folder, 'first_level/z_6m_csf_wm_compcor_M1_fit_MAP_v2/glm2_1_excl/sub-',id];
    spm_mat = [path, '/SPM.mat'];
    cd(path)
    
    for r = 1:numel(roi_files)
        [~, roi_name, ~] = fileparts(roi_files{r});

        % One VOI per ROI per session, defined only by mask
        matlabbatch = [];
        matlabbatch{1}.spm.util.voi.spmmat  = {spm_mat};
        matlabbatch{1}.spm.util.voi.adjust  = 1; % adjust for effects of interest
        matlabbatch{1}.spm.util.voi.session = 1;
        matlabbatch{1}.spm.util.voi.name    = roi_name;

        % ROI: anatomical mask
        matlabbatch{1}.spm.util.voi.roi{1}.mask.image = {sprintf('%s,1', roi_files{r})};
        matlabbatch{1}.spm.util.voi.roi{1}.mask.threshold = 0.1; 

        % Expression: just the mask
        matlabbatch{1}.spm.util.voi.expression = 'i1';

        spm_jobman('run', matlabbatch);


    end
end
