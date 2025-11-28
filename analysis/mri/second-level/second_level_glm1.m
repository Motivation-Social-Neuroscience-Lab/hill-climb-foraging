%%% Second level analysis batch script
%%% created 5 March Emma Scholey for AET analysis
%%%% for GLM2 - separate GLMs for parametric modulators

clear all

spm('defaults','fmri')
spm_jobman('initcfg')

sys_path = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
%subj = [1,2,4, 7:10, 12:31, 33:38, 40:41]; % The file (subject) numbers of the files to be used in the analysis

contrast_include = [1, 2, 3, 4, 5]; 

all_modulator = {'value', 'effort', 'backgroundEffort', 'effortPE', 'unsigned_effortPE'};

for c = contrast_include

    c
    path = [sys_path, 'first_level/z_6m_csf_wm_compcor_M1/glm1_' num2str(c) '/sub-'];

    con_path = [sys_path,  'second_level/z_6m_csf_wm_compcor_M1/glm1_' num2str(c) '/con0001'];
    mkdir(con_path);
    matlabbatch{1}.spm.stats.factorial_design.dir = {con_path};
    
    scanss = cell(numel(subj), 1);
    for j = 1:numel(subj)
        id = num2str(subj(j), '%02d');
        scanss{j} = [path id '/con_0001.nii'];
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
