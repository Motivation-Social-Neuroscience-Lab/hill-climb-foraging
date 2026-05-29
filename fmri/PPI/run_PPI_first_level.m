%%% First level analysis - PPI
%%% created 14 May Emma Scholey for AET analysis

clear all

addpath '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

data_folder = '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
excl_subj = [3,6,39]; % movement issues
subj = setdiff(subj,excl_subj);

val_names = {'sphere_bilat_insula'};

avg_names = {
    'sphere_R_RCZp'
    'sphere_bilat_putamen'
    };

pe_names = {'sphere_R_9m'};

PPI_name = [val_names; avg_names; pe_names];

all_mod_names = [append('value/', val_names); append('backgroundEffort/', avg_names); append('effortPE/', pe_names)];

for m = 1:numel(all_mod_names)
for i = 1:numel(subj)
    cd(data_folder)

    id = num2str(subj(i), '%02d')

    % Get filepaths for all scans
    scan_path = ['../../../../../../../preprocessed/sub-', id, '/func/smooth_sub-', id, '_task-aet_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii,'];
    scanss = cell(1795, 1);
    for j = 1:1795
        scanss{j} = [scan_path num2str(j)];
    end

    path = [data_folder, 'PPI/manual/first_level/glm2_1/', all_mod_names{m}, '/sub-'];

    dir_output = [path,id];
    cd(dir_output)
    load(['PPI_' PPI_name{m} '.mat'])

    % Assign to the matlabbatch structure
    matlabbatch{1}.spm.stats.fmri_spec.dir = {'./'};

    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scanss;
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs'; %timing is in seconds rather than scans
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.254; % the TR
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; %default
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;% default
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''}; %your multiple conditions file name

    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).name = 'PPI-interaction';
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = PPI.ppi;
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'BOLD';
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = PPI.Y;
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'Psych';
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = PPI.P;

    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {['../../../../../../../preprocessed/sub-', id,'/func/nuisance_regressors_fd05_csf_wm_compcor_6m-',id,'.mat']};
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
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'PPI_interaction';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0 ]; % pads tailing zeros
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    %%% Runs batch
    inputs = cell(0, 1);
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch, inputs{:});

end
end