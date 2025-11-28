% Add SPM to MATLAB path and initialize
addpath('/Users/proghani/spm-main');
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Ask the user to enter subject numbers
subject_input = input('Enter subject numbers (comma-separated, no space, single digits with leading zero): ', 's');
subject_numbers = strsplit(subject_input, ',');

% Loop through each subject number
for i = 1:length(subject_numbers)
    subj_num = subject_numbers{i};
    display(subj_num)

    matlabbatch{1}.spm.stats.fmri_spec.dir = {['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/derivatives/first_level/glm3']};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.254;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    %%
    % Define the base path
    scan_path = ['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/func/swusub-', subj_num,'_task-avgenv_run-1_bold.nii'];
    
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
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scanss;
    
    %%
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/rsa_glm_conditions.mat']};
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'easyEnv_lowEff';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'easyEnv_midEff';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 1 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'easyEnv_highEff';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [0 0 1 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'hardEnv_lowEff';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 1 0 0];
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'hardEnv_midEff';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 1 0];
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'hardEnv_highEff';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    nrun = 1; % enter the number of runs here
    inputs = cell(1, nrun);
    for crun = 1:nrun
        inputs{1, crun} = 1; % Results Report: Contrast(s) - cfg_entry
    end
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch, inputs{:});

end