% Define the base directory
baseDir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed';

% Wildcard patterns for files to delete (subject id at the end varies)
deletePatterns = {
    'interpolated*'
    'nuisance_regressors_csf_wm_compcor_6m-*'
    'rp_sub-*'
    'nuisance_regressors_no_compcor-*'
    'nuisance_regressors_6m-*'
    'nuisance_regressors_combined_compcor_6m-*'
    'nuisance_regressors_compcor_6m-*'
    'nuisance_regressors_24m-*'
};

% Get list of subdirectories starting with 'sub-'
subs = dir(fullfile(baseDir, 'sub-*'));
subs = subs([subs.isdir]);

for i = 1:length(subs)
    subPath = fullfile(baseDir, subs(i).name, 'func');

    % Delete files matching each pattern
    for j = 1:length(deletePatterns)
        matches = dir(fullfile(subPath, deletePatterns{j}));
        if isempty(matches)
            fprintf('No matches for %s in %s\n', deletePatterns{j}, subPath);
            continue;
        end
        for k = 1:length(matches)
            filePath = fullfile(subPath, matches(k).name);
            delete(filePath);
            fprintf('Deleted: %s\n', filePath);
        end
    end

end
