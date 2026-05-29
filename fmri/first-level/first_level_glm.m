%%% First level analysis design only batch script
%%% created 6 February 2026, Emma Scholey for AET analysis

clear all 

addpath '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

data_folder = '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
excl_subj = [3,6,39]; % movement issues
subj = setdiff(subj,excl_subj);

for i = 1:numel(subj)
     cd(data_folder)

    id = num2str(subj(i), '%02d')

    % Get filepaths for all scans
    scan_path = ['../../../../preprocessed/sub-', id, '/func/smooth_sub-', id, '_task-aet_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii,'];
    scanss = cell(1795, 1);
    for j = 1:1795
        scanss{j} = [scan_path num2str(j)];
    end

    path = [data_folder, 'first_level/z_6m_csf_wm_compcor_M1_fit_MAP/glm2_1/sub-'];

    dir_output = [path,id];
    cd(dir_output)

    % Assign to the matlabbatch structure
    matlabbatch{1}.spm.stats.fmri_spec.dir = {'./'};

    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scanss;
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs'; %timing is in seconds rather than scans
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.254; % the TR
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; %default
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;% default
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {'conditions_onsets_pmod.mat'}; %your multiple conditions file name
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});%everything else default
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {['../../../../preprocessed/sub-', id,'/func/nuisance_regressors_fd05_csf_wm_compcor_6m-',id,'.mat']};
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'value';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 1];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'background_effort';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 0 1];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'unsigned_effortPE';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    %%% Runs batch
    inputs = cell(0, 1);
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch, inputs{:});

end