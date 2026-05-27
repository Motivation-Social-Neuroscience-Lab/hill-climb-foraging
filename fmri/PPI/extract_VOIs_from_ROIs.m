%% Extract VOI (eigenvariate) from anatomically defined ROIs
% Requires first-level GLM SPM.mat file for each subject, and ROI.nii files
% 

clear all 

addpath '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

data_folder = '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

% roi_files  = {
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_001_Right_8m.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_020_Right_RCZp.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_022_Left_8m.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_041_Left_RCZp.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_027_Left_32d.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_028_Left_32pl.nii'
%     '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/ROIs/roi_masks_1mm_thr50/ROI_033_Left_Area_24.nii'
% };

% sphere masks
roi_files  = {
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_dACC_preSMA_value_+5_+17_+49.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_FPm_background_-14_+58_+6.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_L_insula_value_-31_+22_+6.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_R_insula_value_+31_+24_+6.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_L_pgACC_background_-2_+43_+16.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_L_RCZp_value_-5_-2_+49.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_R_9m_effortPE_+7_+58_+25.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_R_RCZp_background_+10_-7_+42.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_vmPFC_background_+5_+34_-16.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_vmPFC_value_-2_+46_-20.nii'
    % '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_bilateral_insula_value.nii'
     %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/sphere_6mm_bilateral_putamen_background.nii'


    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/bilateral_Putam_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/bilateral_ins_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/ROI_041_Left_RCZp_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/ROI_019_Right_RCZa_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/bilateral_FPm_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/ROI_002_Right_9m_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/ROI_028_Left_32pl_resampled.nii'
    %'/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/ROI_018_Right_Pre_SMA_resampled.nii'
    '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/atlas_masks/R_dmPFC_resampled.nii'

};
%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
% the names of all of your subjects that you have onsets for
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
