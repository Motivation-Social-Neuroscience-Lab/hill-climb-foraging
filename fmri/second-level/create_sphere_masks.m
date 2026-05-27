
%%% Create binary sphere masks from peak MNI coordinates
%%% Emma Scholey for AET analysis

clear all
spm('defaults','fmri')
spm_jobman('initcfg')

% Second-level directory (used to grab a template image for the header)
second_level_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1_fit_MAP/glm2_1_excl/';

% Where to save the sphere masks
out_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/masks/spheres/';
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

% Peak MNI coordinates and labels (one label per row of peak_MNI_list)
peak_MNI_list = [
    -5  -2  49;  %left RCZp     - value
    -2  46 -20;  %vmPFC         - value
   -31  22   6;  %left insula   - value
    31  24   6;  %right insula  - value
     5  17  49;  %dACC (preSMA) - value
    10  -7  42;  %right RCZp    - background
   -14  58   6;  %FPm           - background
     5  34 -16;  %vmPFC         - background
   -31  -2   4;  %left putamen  - background
    26  -2   6;  %right putamen - background
    -2  43  16;  %left pgACC    - background
     7  58  25;  %right 9m      - effort PE
    ];

labels = {
    'L_RCZp_value'
    'vmPFC_value'
    'L_insula_value'
    'R_insula_value'
    'dACC_preSMA_value'
    'R_RCZp_background'
    'FPm_background'
    'vmPFC_background'
    'L_putamen_background'
    'R_putamen_background'
    'L_pgACC_background'
    'R_9m_effortPE'
    };

radius = 6;  % mm

% Use one contrast image as the spatial template (any subject's con works)
template_dir = fullfile(second_level_dir, 'con0001');
cd(template_dir); load SPM.mat
template_img = SPM.xY.P{1};

V = spm_vol(template_img);
[X, Y, Z] = ndgrid(1:V.dim(1), 1:V.dim(2), 1:V.dim(3));
XYZvox  = [X(:) Y(:) Z(:)]';
XYZmm   = V.mat(1:3, :) * [XYZvox; ones(1, size(XYZvox, 2))];

for m = 1:size(peak_MNI_list, 1)

    peak_mni = peak_MNI_list(m, :);

    % Distance from each voxel centre to the peak, in mm
    dist = sqrt(sum(bsxfun(@minus, XYZmm, peak_mni(:)).^2));

    % Binary sphere
    mask = reshape(dist <= radius, V.dim);

    % Write out as NIfTI using the template header
    out_name = sprintf('sphere_%dmm_%s_%+d_%+d_%+d.nii', ...
        radius, labels{m}, peak_mni(1), peak_mni(2), peak_mni(3));
    out_path = fullfile(out_dir, out_name);

    V_out = V;
    V_out.fname   = out_path;
    V_out.dt      = [spm_type('uint8') 0];
    V_out.pinfo   = [1; 0; 0];
    V_out.descrip = sprintf('%dmm sphere at [%d %d %d] (%s)', ...
        radius, peak_mni(1), peak_mni(2), peak_mni(3), labels{m});

    spm_write_vol(V_out, double(mask));

    fprintf('Saved %s (%d voxels)\n', out_name, sum(mask(:)));
end

% Create bilateral spherical insula mask
L_insula_path = fullfile(out_dir, sprintf('sphere_%dmm_L_insula_value_%+d_%+d_%+d.nii', radius, -31, 22, 6));
R_insula_path = fullfile(out_dir, sprintf('sphere_%dmm_R_insula_value_%+d_%+d_%+d.nii', radius, 31, 24, 6));

V_L = spm_vol(L_insula_path);  mask_L = spm_read_vols(V_L);
V_R = spm_vol(R_insula_path);  mask_R = spm_read_vols(V_R);

mask_bilateral = double(mask_L | mask_R);

V_out = V_L;
V_out.fname   = fullfile(out_dir, sprintf('sphere_%dmm_bilateral_insula_value.nii', radius));
V_out.dt      = [spm_type('uint8') 0];
V_out.pinfo   = [1; 0; 0];
V_out.descrip = sprintf('%dmm bilateral insula sphere', radius);
spm_write_vol(V_out, mask_bilateral);
fprintf('Saved bilateral insula mask (%d voxels)\n', sum(mask_bilateral(:)));

% Create bilateral spherical putamen mask
L_putamen_path = fullfile(out_dir, sprintf('sphere_%dmm_L_putamen_background_%+d_%+d_%+d.nii', radius, -31, -2, 4));
R_putamen_path = fullfile(out_dir, sprintf('sphere_%dmm_R_putamen_background_%+d_%+d_%+d.nii', radius, 26, -2, 6));

V_L = spm_vol(L_putamen_path);  mask_L = spm_read_vols(V_L);
V_R = spm_vol(R_putamen_path);  mask_R = spm_read_vols(V_R);

mask_bilateral = double(mask_L | mask_R);

V_out = V_L;
V_out.fname   = fullfile(out_dir, sprintf('sphere_%dmm_bilateral_putamen_background.nii', radius));
V_out.dt      = [spm_type('uint8') 0];
V_out.pinfo   = [1; 0; 0];
V_out.descrip = sprintf('%dmm bilateral putamen sphere', radius);
spm_write_vol(V_out, mask_bilateral);
fprintf('Saved bilateral putamen mask (%d voxels)\n', sum(mask_bilateral(:)));


%% ============================= create ROI masks - helper functions
function combine_masks(mask1_file, mask2_file, output_file)
% Combine two ROI masks into a bilateral mask

    % Load both masks
    V1 = spm_vol(mask1_file);
    V2 = spm_vol(mask2_file);

    mask1 = spm_read_vols(V1);
    mask2 = spm_read_vols(V2);

    % Combine masks (union - any voxel that's active in either mask)
    combined_mask = (mask1 > 0) | (mask2 > 0);

    % Convert back to numeric (1 for active voxels)
    combined_mask = double(combined_mask);

    % Save combined mask using first mask's header
    V_out = V1;
    V_out.fname = output_file;
    V_out.descrip = 'Bilateral combined ROI';
    spm_write_vol(V_out, combined_mask);

    disp(['Combined mask saved: ' output_file]);
    disp(['Total voxels in bilateral mask: ' num2str(sum(combined_mask(:)))]);

end

function roi_resampled = resample_to_template(roi_file, template_file)
% Resample ROI to match template space and resolution

    V_roi = spm_vol(roi_file);
    V_template = spm_vol(template_file);

    % Read ROI and template
    roi_data = spm_read_vols(V_roi);
    template_data = spm_read_vols(V_template);

    % Create output volume with template dimensions
    output_data = zeros(V_template(1).dim);

    % For each voxel in template, find corresponding ROI voxel using affine transformation
    [x_t, y_t, z_t] = ndgrid(1:V_template(1).dim(1), 1:V_template(1).dim(2), 1:V_template(1).dim(3));

    % Convert template voxel coords to physical coords
    coords_t = V_template(1).mat * [x_t(:)'; y_t(:)'; z_t(:)'; ones(1, numel(x_t))];

    % Convert physical coords to ROI voxel coords
    coords_r = V_roi(1).mat \ coords_t;

    % Interpolate ROI data at these coordinates (nearest neighbor)
    x_r = round(coords_r(1,:));
    y_r = round(coords_r(2,:));
    z_r = round(coords_r(3,:));

    % Only sample voxels within ROI bounds
    valid = (x_r >= 1) & (x_r <= V_roi(1).dim(1)) & ...
            (y_r >= 1) & (y_r <= V_roi(1).dim(2)) & ...
            (z_r >= 1) & (z_r <= V_roi(1).dim(3));

    idx = sub2ind(V_roi(1).dim, x_r(valid), y_r(valid), z_r(valid));
    output_idx = find(valid);
    output_data(output_idx) = roi_data(idx);

    % Save resampled ROI
    [path, name, ~] = fileparts(roi_file);
    roi_resampled = fullfile(path, [name '_resampled.nii']);

    V_out = V_template(1);
    V_out.fname = roi_resampled;
    V_out.descrip = 'Resampled ROI';
    spm_write_vol(V_out, output_data);

end
