% Add SPM to MATLAB path and initialize
addpath('/Users/proghani/spm-main');
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Ask the user to enter subject numbers
subject_input = input('Enter subject numbers (comma-separated, single digits with leading zero): ', 's');
subject_numbers = strsplit(subject_input, ',');

% Loop through each subject number
for i = 1:length(subject_numbers)
    subj_num = subject_numbers{i};

    % Define the base path
    scan_path = ['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/func/wusub-', subj_num,'_task-avgenv_run-1_bold.nii'];
    
    % Get the number of volumes in the NIfTI file
    V = spm_vol(scan_path);
    num_volumes = numel(V);
    % display(num_volumes)
    
    % Initialize the cell array 
    scanss = cell(num_volumes, 1);
    
    % Use a for loop to fill in the cell array
    for j = 1:num_volumes
        scanss{j} = [scan_path, ',', num2str(j)];
    end

    % Assign to the matlabbatch structure
    matlabbatch{1}.spm.spatial.smooth.data = scanss;

    matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = 'ls';
    
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);

end



 