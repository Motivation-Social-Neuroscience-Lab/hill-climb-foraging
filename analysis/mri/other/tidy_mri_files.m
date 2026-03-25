% Define the base directory
baseDir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed';

% List of files to delete
filesToDelete = {
    'model_estimates_M1_fit.csv', ...
    'model_estimates_M5.csv', ...
    'model_estimates_z_score_M5.csv', ...
    'model_estimates_z_score_M18.csv'
};

% Get list of subdirectories starting with 'sub-'
subs = dir(fullfile(baseDir, 'sub-*'));

for i = 1:length(subs)
    subPath = fullfile(baseDir, subs(i).name);
    
    % Delete specified files
    for j = 1:length(filesToDelete)
        filePath = fullfile(subPath, filesToDelete{j});
        if exist(filePath, 'file')
            delete(filePath);
            fprintf('Deleted: %s\n', filePath);
        else
            fprintf('Not found (skipped): %s\n', filePath);
        end
    end
    
    % Rename model_estimates_z_score_M1.csv to model_estimates_M1.csv
    oldFile = fullfile(subPath, 'model_estimates_z_score_M1.csv');
    newFile = fullfile(subPath, 'model_estimates_M1.csv');
    
    if exist(oldFile, 'file')
        movefile(oldFile, newFile);
        fprintf('Renamed: %s → %s\n', oldFile, newFile);
    else
        fprintf('M1 file not found (skipped rename): %s\n', oldFile);
    end
end
