%%% Second level analysis batch script
%%% created 27 February Emma Scholey for AET analysis
%%%% for GLM1 - background effort only

clear all

spm('defaults','fmri')
spm_jobman('initcfg')

sys_path = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
excl_subj = [3,6,39]; % movement issues
subj = setdiff(subj,excl_subj);

all_modulator = {'value', 'backgroundEffort', 'unsigned_effortPE'};
n_contrast = length(all_modulator);

path = [sys_path, 'first_level/z_6m_csf_wm_compcor_M1_fit_MAP_v2/glm2_1_excl/sub-'];

for c = 1:n_contrast

    c
    con_path = [sys_path,  'second_level/z_6m_csf_wm_compcor_M1_fit_MAP_v2/glm2_1_excl/con000',num2str(c)];
    mkdir(con_path);
    matlabbatch{1}.spm.stats.factorial_design.dir = {con_path};
    
    scanss = cell(numel(subj), 1);
    for j = 1:numel(subj)
        id = num2str(subj(j), '%02d');
        scanss{j} = [path id '/con_000' num2str(c), '.nii'];
    end

    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = scanss;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = [all_modulator{c}, '_pos'];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = [all_modulator{c}, '_neg'];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [-1];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.delete = 0;



    %%% Runs batch
    inputs = cell(0, 1);
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch, inputs{:});

end
