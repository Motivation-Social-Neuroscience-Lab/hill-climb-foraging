%%% Extract contrast estimates for voxels of interest
%%% created 16 June 2025 Emma Scholey for AET analysis

clear all
spm('defaults','fmri')
spm_jobman('initcfg')


base_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1/glm2/';

con_folder = {'con0001', 'con0002', 'con0003'};

% Define MNI coordinates (rows = different peaks)
mni_coords = [
    % value pos peaks
    -5, -2, 49;
    36, 41, -6;
    -38, 31, -11;
    -19, 48, 1;
    % value neg peaks
    2, 17, 47;
    34, 22, 6;
    -36, 22, -4;
    % background peaks
    7, -17, 49;
    7, 29, -11;
    -7, 29, 18;
    -2, 48, -8;
    % effort PE peaks
    7, 58, 25;
    5, 29, -16;

    ];


for i = 1:length(con_folder)
    cd([base_dir, con_folder{i}]); load SPM.mat
    con_files = SPM.xY.P;
    V = spm_vol(con_files);
    Y(:,:,i) = extract_peak_data(mni_coords, V); 

end

save('../contrast_estimates_peak_voxels.mat')


function data_matrix = extract_peak_data(mni_coords, con_images)
% Extract contrast values at given MNI coordinates for each subject
%
% Inputs:
% - mni_coords: N x 3 matrix of MNI peak coordinates
% - con_images: cell array of full paths to each subject's contrast image
%
% Output:
% - data_matrix: N x num_subjects matrix of contrast estimates

num_coords = size(mni_coords, 1);
num_subjects = length(con_images);

data_matrix = nan(num_subjects, num_coords);

for subj = 1:num_subjects
    V = spm_vol(con_images{subj});

    for i = 1:num_coords
        % Convert MNI to voxel
        voxel_coord = round(inv(V.mat) * [mni_coords(i,:) 1]');
        voxel_coord = voxel_coord(1:3);

        % Get value at that voxel
        data_matrix(subj,i) = spm_get_data(V, voxel_coord);
    end
end

end

