clear all 

addpath '/rds/projects/a/appsmaj-motivation-social-neuro/Emma/spm'

spm('defaults','fmri')
spm_jobman('initcfg')

path = '/rds/projects/a/appsmaj-motivation-social-neuro/Emma/aet_fMRI/preprocessed/';
%path = '/Users/exs165/Dropbox/average-effort/data_derived/mri/';
spm_path = '/rds/projects/a/appsmaj-motivation-social-neuro/Emma/spm/';

% List of open inputs
subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
subj = [34:41];
%-----------------------------------------------------------------------
% Job saved on 03-Feb-2025 18:36:28 by cfg_util (rev $Rev: 8183 $)
% spm SPM - SPM25 (25.01.02)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

for i = [1:numel(subj)]

id = num2str(subj(i), '%02d');

gunzip([path, 'sub-', id, '/func/sub-', id, '_task-aet_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'])

matlabbatch{1}.spm.spatial.smooth.data(1) = {[path, 'sub-', id, '/func/sub-', id, '_task-aet_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii']};
matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = 'smooth_';


inputs = cell(0, 1);
spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch, inputs{:});

end