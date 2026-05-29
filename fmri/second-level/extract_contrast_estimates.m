

%%% Extract contrast estimates for voxels of interest
%%% created 16 June 2025 Emma Scholey for AET analysis

clear all
spm('defaults','fmri')
spm_jobman('initcfg')

% First-level base directory
second_level_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1_fit_MAP/glm2_1_excl/';

% Define ROIs
ROI_path = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/masks/spheres/';

 mask_list = {
'sphere_6mm_L_RCZp_value_-5_-2_+49.nii'
'sphere_6mm_vmPFC_value_-2_+46_-20.nii'
'sphere_6mm_bilateral_insula_value.nii'
'sphere_6mm_dACC_preSMA_value_+5_+17_+49.nii'
'sphere_6mm_R_RCZp_background_+10_-7_+42.nii'
'sphere_6mm_FPm_background_-14_+58_+6.nii'
'sphere_6mm_vmPFC_background_+5_+34_-16.nii'
'sphere_6mm_bilateral_putamen_background.nii'
'sphere_6mm_L_pgACC_background_-2_+43_+16.nii'
'sphere_6mm_R_9m_effortPE_+7_+58_+25.nii'

    };


% Contrast to extract
con_file = {'con0001' ,'con0002', 'con0003'};

for r = 1:numel(mask_list)

    ROI = [ROI_path mask_list{r}]

    for c = 1:numel(con_file)

        cd(fullfile(second_level_dir, con_file{c})); load SPM.mat

        % Extract ROI data for this subject
        subject_sphere_data(:,r,c) = Extract_Mask_Data(ROI, SPM.xY.P);

    end

end

save('../contrast_estimates_6mm_sphere.mat', "subject_sphere_data") % saves in 2nd-level folder

function mn = Extract_Mask_Data(ROI, Contrast)

Y = spm_read_vols(spm_vol(ROI),1);
indx = find(Y>0);
[x,y,z] = ind2sub(size(Y),indx);

XYZ = [x y z]';

ROI_data = spm_get_data(Contrast, XYZ);   % subjects × voxels
ROI_data = ROI_data(:, ~any(isnan(ROI_data),1));
mn = mean(ROI_data, 2);

end

