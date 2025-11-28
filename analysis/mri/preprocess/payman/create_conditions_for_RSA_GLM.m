clear all

% Prompt the user to enter the subject number
subj_num = input('Enter the subject number (single digit values should have a leading 0, e.g., 02): ', 's');

% Define the file paths
modelEstimatesPath = ['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/model_estimates_M37.csv'];
cueOnsetsPath = ['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/cueOnsets.csv'];

% Read the CSV files
modelEstimates = readtable(modelEstimatesPath);
cueOnsets = readmatrix(cueOnsetsPath);

% Ensure the number of rows match
if height(modelEstimates) ~= length(cueOnsets)
    error('The number of rows in the CSV files do not match.');
end

% Define the conditions
blockTypes = [99, 11];
blockNames = {'hardEnv', 'easyEnv'};
realEfforts = [1, 2, 3];
effortNames = {'lowEff', 'midEff', 'highEff'};

% Initialize cell arrays
names = cell(6, 1);
onsets = cell(6, 1);
durations = cell(6, 1);

% Generate condition names, onsets and durations
conditionIdx = 1;
for b = 1:length(blockTypes)
    for e = 1:length(realEfforts)
        conditionName = [blockNames{b}, '_', effortNames{e}];
        conditionOnsets = cueOnsets(modelEstimates.blockType == blockTypes(b) & modelEstimates.realEffort == realEfforts(e));
        
        names{conditionIdx} = conditionName;
        onsets{conditionIdx} = conditionOnsets;
        durations{conditionIdx} = zeros(size(conditionOnsets)); % Set durations to be the same size as onsets
        
        conditionIdx = conditionIdx + 1;
    end
end

% Save to .mat file
save(['/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/sub-', subj_num,'/rsa_glm_conditions.mat'], 'names', 'onsets', 'durations');

disp('Data has been successfully saved to rsa_glm_conditions.mat');
