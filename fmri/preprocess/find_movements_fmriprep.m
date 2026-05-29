%%%%Finding large movements%%%%
% Emma Scholey 25 April 2025
% Find problematic scans with high movements/rotations
% Assumes using fmriPrep

clear
close all
clc

dir_input = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis

fwd_thresh = 0.5; % Most use 0.5 for adults (e.g. Siegel et al 2014). Could choose to be more lenient for high motion data (e.g. 0.9)

all_scan_number_fwd = cell(size(subj));
mean_fwd = double(size(subj));

for s = 1:length(subj)

    scan_number_fwd = [];

    %% MOTION
    id = num2str(subj(s), '%02d'); id
    timeseries = readtable([dir_input, 'sub-', id, '/func/sub-', id, '_task-aet_run-1_desc-confounds_timeseries.tsv'], "FileType","text",'Delimiter', '\t');

    rigid_body_parameters_6m = timeseries(:,ismember(timeseries.Properties.VariableNames,{'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'} ));

    fwd = timeseries(:,ismember(timeseries.Properties.VariableNames,{'framewise_displacement', 'std_dvars'} ));
    flag_fwd = find(abs(fwd.framewise_displacement) > fwd_thresh);
    scan_number_fwd = [scan_number_fwd; flag_fwd];

     mean_fwd(s) = mean(fwd.framewise_displacement, "omitmissing");

    all_scan_number_fwd{s} = unique(scan_number_fwd);

    %% CompCor regressors
    csf_wm_comp_cor = timeseries(:,ismember(timeseries.Properties.VariableNames,{'c_comp_cor_00', 'c_comp_cor_01', 'c_comp_cor_02', 'c_comp_cor_03', 'c_comp_cor_04','c_comp_cor_05','w_comp_cor_00', 'w_comp_cor_01', 'w_comp_cor_02', 'w_comp_cor_03', 'w_comp_cor_04', 'w_comp_cor_05'} ));

    %% Concatenate all

    % include scrub regressor for bad scans
    all_scans = false(1, size(timeseries,1));
    all_scans(scan_number_fwd) = true;
    all_scans = array2table(all_scans');all_scans.Properties.VariableNames = {'scrub'};

    nuisance_regressors = [rigid_body_parameters_6m, csf_wm_comp_cor, all_scans];
    names = nuisance_regressors.Properties.VariableNames;
    R = table2array(nuisance_regressors);
    save([dir_input, 'sub-', id, '/func/nuisance_regressors_fd05_csf_wm_compcor_6m-', id, '.mat'], 'R', 'names')

    %% Save mean framewise displacement for 2nd level 
    clear timeseries
end

 save([dir_input, 'mean_fwd.mat'], 'mean_fwd')

fwd_thresh = 3*std(mean_fwd);

% SUMMARY 
nScansRemoved = [];
for s = 1:length(subj)
nScansRemoved(s) = length(all_scan_number_fwd{s});
end

excl_index = mean_fwd >= fwd_thresh;
excl_subj = subj(excl_index)

nScansRemoved(excl_index) = [];
percentScansRemoved = nScansRemoved/1795 * 100 % remove over 20% (excludes same subjects as 3*STD exclusion criteria above) 
mean(percentScansRemoved)
std(percentScansRemoved)