%%%%Finding large movements%%%%
% Emma Scholey 25 April 2025
% Find problematic scans with high movements/rotations
% Assumes using fmriPrep
% fmriPrep uses FSL mcflirt for estimating rigid body parameters
% Reference volume is median motion-corrected (or dummy scans if deteced)
% Selected threshold:
% Relative motion - Andy Jahn recommends half of the voxel resolution
% Absolute motion - Andy Jahn recommends voxel resolution
% Note - could also use framewise displacement/DVAR parameters instead -
% check that these mostly align (FWD and DVAR seem more conservative)

% 6m - for scrubbing volumes
% 24m - for including as nuisance regressors at first level
% CSF and WM global signal - for including as nuisance regressors at first
% level 
% mean framewise displacement per subject - for including as nuisance
% regressor at second level 

clear all
close all
clc

dir_input = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis

% rel_motion_thresh = 1.2; % I'm being more conservative than half voxel
% abs_motion_thresh = 2.4;
fwd_thresh = 0.9; % Most use 0.5 for adults (e.g. Siegel et al 2014), but this is quite aggressive. Since we're squeezing, make more lenient.
% also, Fwd is very conservative for multiband, as it relies on TR, which
% is very low. So make more lenient. (0.9 threshold recommended for
% kids/clinical populations).

%figure, m = tiledlayout('flow');
all_scan_number_abs_motion = {};
all_scan_number_rel_motion = {};

for s = 1:length(subj)

    % scan_number_abs_motion = [];
    % scan_number_rel_motion = [];
    scan_number_fwd = [];

    %% MOTION
    id = num2str(subj(s), '%02d'); id
    timeseries = readtable([dir_input, 'sub-', id, '/func/sub-', id, '_task-aet_run-1_desc-confounds_timeseries.tsv'], "FileType","text",'Delimiter', '\t');

    rigid_body_parameters_6m = timeseries(:,ismember(timeseries.Properties.VariableNames,{'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'} ));
    % rigid_body_parameters_24m = timeseries(:,startsWith(timeseries.Properties.VariableNames,{'trans', 'trans', 'trans', 'rot', 'rot', 'rot'} ));

    motion = table2array(rigid_body_parameters_6m);
    motion(:,4:6) = motion(:,4:6)*180/pi; % convert rotation parameters from radians to degrees
    nexttile(s), plot(abs(motion)), ylim([-6 6])

    fwd = timeseries(:,ismember(timeseries.Properties.VariableNames,{'framewise_displacement', 'std_dvars'} ));
    flag_fwd = find(abs(fwd.framewise_displacement) > fwd_thresh);
    scan_number_fwd = [scan_number_fwd; flag_fwd];

    % Check relative motion
    % for i = 1:6 %for X, Y and Z directions
    %     flag_abs_motion = find(abs(motion(:,i)) > abs_motion_thresh); % compared to reference slice
    %     flag_rel_motion = find(abs(diff(motion(:,i))) > rel_motion_thresh); % frame to frame
    % 
    %     scan_number_abs_motion = [scan_number_abs_motion; flag_abs_motion]; %
    %     scan_number_rel_motion = [scan_number_rel_motion; flag_rel_motion+1]; % + 1 because calculating diff (relative difference)
    % 
    % 
    % end

     mean_fwd(s) = mean(fwd.framewise_displacement, "omitmissing");
    % 
    % all_scan_number_abs_motion{s} = unique(scan_number_abs_motion);
    % all_scan_number_rel_motion{s} = unique(scan_number_rel_motion);
    all_scan_number_fwd{s} = unique(scan_number_fwd);

    %writematrix(scan_number_fwd,[dir_input, 'sub-', id, '/func/rp_sub-', id, '_interpolated_scans.txt'])

    %% CompCor regressors
    csf_wm_comp_cor = timeseries(:,ismember(timeseries.Properties.VariableNames,{'c_comp_cor_00', 'c_comp_cor_01', 'c_comp_cor_02', 'c_comp_cor_03', 'c_comp_cor_04','w_comp_cor_00', 'w_comp_cor_01', 'w_comp_cor_02', 'w_comp_cor_03', 'w_comp_cor_04'} ));
    combined_comp_cor = timeseries(:,ismember(timeseries.Properties.VariableNames,{'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', 'a_comp_cor_03', 'a_comp_cor_04'} ));

    % %% Corresponding cosine regressors - DO NOT INCLUDE (we're doing
    % separate 128 Hz high pass filter, which is the same as including
    % cosine regressors I think)
    % cosine_parameters = timeseries(:,ismember(timeseries.Properties.VariableNames,{'cosine00', 'cosine01', 'cosine02', 'cosine03'} ));

    %% Mean tissue signal
    % phys_signal = timeseries(:,ismember(timeseries.Properties.VariableNames,{'csf', 'white_matter'} ));

    %% Concatenate all

    % include scrub regressor for bad scans
    all_scans = false(1, size(timeseries,1));
    all_scans(scan_number_fwd) = true;
    all_scans = array2table(all_scans');all_scans.Properties.VariableNames = {'scrub'};

    nuisance_regressors = [rigid_body_parameters_6m, combined_comp_cor, all_scans];
    names = nuisance_regressors.Properties.VariableNames;
    R = table2array(nuisance_regressors);

    %R(isnan(R)) = 0; % replace nans of derivatives
    %save([dir_input, 'sub-', id, '/func/nuisance_regressors_combined_compcor_6m-', id, '.mat'], 'R', 'names')
   
    nuisance_regressors = [rigid_body_parameters_6m, csf_wm_comp_cor, all_scans];
    names = nuisance_regressors.Properties.VariableNames;
    R = table2array(nuisance_regressors);
    %save([dir_input, 'sub-', id, '/func/nuisance_regressors_csf_wm_compcor_6m-', id, '.mat'], 'R', 'names')

    % nuisance_regressors_no_compcor = [rigid_body_parameters, all_scans];
    % R = table2array(nuisance_regressors_no_compcor);
    % names = nuisance_regressors_no_compcor.Properties.VariableNames;
    % save([dir_input, 'sub-', id, '/func/nuisance_regressors_no_compcor-', id, '.mat'], 'R', 'names')

    %% Save mean framewise displacement for 2nd level 
    clear timeseries
end

% save([dir_input, 'mean_fwd.mat'], 'mean_fwd')
% 
fwd_thresh = 3*std(mean_fwd);
find(mean_fwd >= fwd_thresh)

nScansRemoved = [];
for s = 1:length(all_scan_number_fwd)
nScansRemoved(s) = length(all_scan_number_fwd{s});
end

percentScansRemoved = nScansRemoved/1795; 
mean(percentScansRemoved)*100
std(percentScansRemoved)*100