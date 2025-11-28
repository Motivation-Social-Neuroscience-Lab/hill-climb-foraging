%%% First level analysis design only batch script
%%% created 6 February Emma Scholey for AET analysis

clear all 

%addpath '/rds/projects/a/appsmaj-motivation-social-neuro/Emma/spm'
%addpath '/Volumes/appsmaj-motivation-social-neuro/Emma/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

%path = '/rds/projects/a/appsmaj-motivation-social-neuro/Emma/average-effort/data_derived/mri/1st-level/glm1/sub-';
path = '/Users/exs165/Dropbox/average-effort/data_derived/mri/1st-level/glm1/sub-';
%path = '/Volumes/appsmaj-motivation-social-neuro/Emma/average-effort/data_derived/mri/1st-level/glm1/sub-';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
% the names of all of your subjects that you have onsets for
subj = [15:31, 33:41]
for i = 1:numel(subj)
    id = num2str(subj(i), '%02d')

    dir_output = [path,id];
    cd(dir_output)

    %% 1st-level specification
    matlabbatch{1}.spm.stats.fmri_spec.dir = {'./'};

    % Get filepaths for all scans
    scan_path = ['../../../processed/sub-', id, '/swu_sub-', id, '_task-aet_run-1_bold.nii,'];
    scanss = cell(1795, 1);
    for j = 1:1795
        scanss{j} = [scan_path num2str(j)];
    end

    % BUT if interpolated scans, add them here and replace accordingly 
    all_bad_scans = readmatrix(['../../../processed/sub-', id, '/rp_sub-',id, '_interpolated_scans.txt']);

    if ~isempty(all_bad_scans)
        for j = 1:length(all_bad_scans)
            bad_scan = all_bad_scans(j);
            scanss{bad_scan} = ['../../../processed/sub-', id, '/swu_sub-', id, '_task-aet_run-1_bold_interpolate_', num2str(bad_scan), '.nii'];
        end
    end

    % Assign to the matlabbatch structure
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scanss;
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs'; %timing is in seconds rather than scans
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.254; % the TR
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; %default
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;% default
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {'conditions_onsets_pmod.mat'}; %your multiple conditions file name
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});%everything else default
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {['../../../processed/sub-', id,'/movement_regressors_sub-',id,'.txt']};
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;

    %% Run 1st-level model 
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'value';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 1 0 0 0 0 0 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'effort';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 0 1 0 0 0 0 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'background_effort';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 1 0 0 0 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'effort_exerted';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 0 0 1 0 0 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'reward';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 0 0 0 1 0 0 0];
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    %%% Opens directory and saves batch so can be loaded and compared with GUI version
    save(fullfile(dir_output, 'glm1_background_effort.mat'), 'matlabbatch')

    %%% Runs batch
    inputs = cell(0, 1);
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch, inputs{:});

end