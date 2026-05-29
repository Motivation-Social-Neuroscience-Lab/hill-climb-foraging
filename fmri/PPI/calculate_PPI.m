%%% PPI calculation batch script
%%% created 14 May 2026 Emma Scholey for AET analysis

clear all

addpath '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/spm'

spm('defaults','fmri')

sys_path = '/rds/projects/a/appsmaj-effort-prey-fmri-scholey/aet_fMRI/';

%%% Subject IDs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
excl_subj = [3,6,39];
subj = setdiff(subj,excl_subj);

val_ppi = {'VOI_sphere_6mm_bilateral_insula_value_1.mat'};
val_names = {'sphere_bilat_insula'};

avg_ppi = {
    'VOI_sphere_6mm_R_RCZp_background_+10_-7_+42_1.mat'
    'VOI_sphere_6mm_bilateral_putamen_background_1.mat'
    };
avg_names = {
    'sphere_R_RCZp'
    'sphere_bilat_putamen'
    };

pe_ppi = {'VOI_sphere_6mm_R_9m_effortPE_+7_+58_+25_1.mat'};
pe_names = {'sphere_R_9m'};

for s = 1:numel(subj)

    id = num2str(subj(s), '%02d');
    subj_spm_path = [sys_path, 'first_level/z_6m_csf_wm_compcor_M1_fit_MAP_v2/glm2_1_excl/sub-' id];

    % VALUE
    for v = 1:length(val_ppi)

        mod_path = [sys_path,  'PPI/manual/first_level/glm2_1/value/', val_names{v}, '/sub-', id];
        mkdir(mod_path); cd(mod_path)

        matlabbatch{1}.spm.stats.ppi.spmmat = {[subj_spm_path, '/SPM.mat']};
        matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {[subj_spm_path, '/', val_ppi{v}]};
        matlabbatch{1}.spm.stats.ppi.type.ppi.u = [1 2 1];
        matlabbatch{1}.spm.stats.ppi.name = val_names{v};
        matlabbatch{1}.spm.stats.ppi.disp = 0;

        %%% Runs batch
        inputs = cell(0, 1);
        spm_jobman('run', matlabbatch, inputs{:});

        ppi_file = [subj_spm_path, '/PPI_', val_names{v}, '.mat'];
        movefile(ppi_file, mod_path);
    end

    % BACKGROUND
    for a = 1:numel(avg_ppi)

        mod_path = [sys_path,  'PPI/manual/first_level/glm2_1/backgroundEffort/' avg_names{a}, '/sub-', id];
        mkdir(mod_path); cd(mod_path)

        matlabbatch{1}.spm.stats.ppi.spmmat = {[subj_spm_path, '/SPM.mat']};
        matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {[subj_spm_path, '/', avg_ppi{a}]};
        matlabbatch{1}.spm.stats.ppi.type.ppi.u = [1 3 1];
        matlabbatch{1}.spm.stats.ppi.name = avg_names{a};
        matlabbatch{1}.spm.stats.ppi.disp = 0;

        %%% Runs batch
        inputs = cell(0, 1);
        spm_jobman('run', matlabbatch, inputs{:});

        ppi_file = [subj_spm_path, '/PPI_', avg_names{a}, '.mat'];
        movefile(ppi_file, mod_path);

    end

    % EFFORT PE
    for p = 1:numel(pe_ppi)

        mod_path = [sys_path,  'PPI/manual/first_level/glm2_1/effortPE/' pe_names{p}, '/sub-', id];
        mkdir(mod_path); cd(mod_path)

        matlabbatch{1}.spm.stats.ppi.spmmat = {[subj_spm_path, '/SPM.mat']};
        matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {[subj_spm_path, '/', pe_ppi{p}]};
        matlabbatch{1}.spm.stats.ppi.type.ppi.u = [1 4 1];
        matlabbatch{1}.spm.stats.ppi.name = pe_names{p};
        matlabbatch{1}.spm.stats.ppi.disp = 0;

        %%% Runs batch
        inputs = cell(0, 1);
        spm_jobman('run', matlabbatch, inputs{:});

        ppi_file = [subj_spm_path, '/PPI_', pe_names{p}, '.mat'];
        movefile(ppi_file, mod_path);

    end


end