

%%% Extract contrast estimates for voxels of interest
%%% created 16 June 2025 Emma Scholey for AET analysis

clear all
spm('defaults','fmri')
spm_jobman('initcfg')

% First-level base directory
second_level_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1_fit_MAP/glm2_1_excl/';

% Define ROIs
%ROI_path = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/masks/atlas_masks/';
ROI_path = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/masks/spheres/';

 mask_list = {
%     'ROI_018_Right_Pre_SMA_resampled.nii'
%     'bilateral_FPm_resampled.nii'
%     'ROI_028_Left_32pl_resampled.nii'
%     'ROI_002_Right_9m_resampled.nii'
%     'ROI_019_Right_RCZa_resampled.nii'
%     'ROI_041_Left_RCZp_resampled.nii'
%     'bilateral_MI_resampled.nii'
%     'bilateral_Putam_resampled.nii'
%        'bilateral_AVI_resampled.nii'
%'bilateral_ins_resampled.nii'
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


% peak_MNI_list = [
%     -5 -2 49; %left RCZp - value
%         -2 46 -20; %vmPFC - value
%     -31 22 6; %left insula - value
%     31 24 6; %right insula - value 
%     5 17 49; %dACC - value (preSMA)
%         10 -7 42; %right RCZp - background
%     -14 58 6; %FPm - background
%     5 34 -16; %vmPFC - background
%     -31 -2 4; % left putamen - background
%     26 -2 6; % right putamen - background
%     -2 43 16; % left pgACC - background
%     7 58 25; %right 9m - effort PE
%     ];
% 
% radius = 6; 

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

% 
% for m = 1:size(peak_MNI_list,1)
% 
%     peak_MNI = peak_MNI_list(m,:);
% 
%     for c = 1:numel(con_file)
% 
%         cd(fullfile(second_level_dir, con_file{c})); load SPM.mat
% 
%         % Extract sphere data for this subject
%         subject_sphere_data(:,m,c) = Extract_Sphere_Data(peak_MNI, radius, SPM.xY.P);
%     end
% 
% end
% 
% save('../contrast_estimates_peak_6mm.mat', "subject_sphere_data") % saves in 2nd-level folder
% 

function mn = Extract_Mask_Data(ROI, Contrast)

% if ~contains(ROI, 'resampled')
%     ROI = resample_to_template(ROI, Contrast{1});
% end

Y = spm_read_vols(spm_vol(ROI),1);
indx = find(Y>0);
[x,y,z] = ind2sub(size(Y),indx);

XYZ = [x y z]';

ROI_data = spm_get_data(Contrast, XYZ);   % subjects × voxels
ROI_data = ROI_data(:, ~any(isnan(ROI_data),1));
mn = mean(ROI_data, 2);

end

% function mn = Extract_Sphere_Data(peak_mni, radius, Contrast)
% 
% % if ~contains(ROI, 'resampled')
% %     ROI = resample_to_template(ROI, Contrast{1});
% % end
% 
% V       = spm_vol(Contrast{1});   % any subject's con image for the header
% [X,Y,Z] = ndgrid(1:V.dim(1), 1:V.dim(2), 1:V.dim(3));
% XYZvox  = [X(:) Y(:) Z(:)]';
% XYZmm   = V.mat(1:3,:) * [XYZvox; ones(1, size(XYZvox, 2))];
% 
% dist       = sqrt(sum(bsxfun(@minus, XYZmm, peak_mni(:)).^2));
% sphere_XYZ = XYZvox(:, dist <= radius);
% 
% sphere_data = spm_get_data(Contrast, sphere_XYZ);   % subjects × voxels
% sphere_data = sphere_data(:, ~any(isnan(sphere_data),1));
% mn = mean(sphere_data, 2);
% 
% end

