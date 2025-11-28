clear 

% Prompt the user to enter the subject number
subjectNumber = input('Enter the subject number (single digit values should have a leading 0, e.g., 02): ', 's');

% Construct the file paths based on the entered subject number
baseFolder = '/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/';
subjectFolder = fullfile(baseFolder, ['sub-', subjectNumber]);
cueOnsetsPath = fullfile(subjectFolder, 'cueOnsets.csv');
exertOnsetsPath = fullfile(subjectFolder, 'exertOnsets.csv');
feedbackOnsetsPath = fullfile(subjectFolder, 'feedbackOnsets.csv');
modelEstimatesPath = fullfile(subjectFolder, 'model_estimates_M37.csv')

% Read the CSV files to get the onsets
cueOnsets = csvread(cueOnsetsPath);
exertOnsets = csvread(exertOnsetsPath);
feedbackOnsets = csvread(feedbackOnsetsPath);

% Read the model estimates CSV file to get the backgroundEffort values
modelEstimates = readtable(modelEstimatesPath);
backgroundEffort = modelEstimates.backgroundEffort;

% Create cell arrays for names, onsets, and durations
names = {'cueOnset', 'exertOnset', 'feedbackOnset'};
onsets = {cueOnsets, exertOnsets, feedbackOnsets};
durations = {zeros(size(cueOnsets)), zeros(size(exertOnsets)), zeros(size(feedbackOnsets))};

% Normalize the backgroundEffort values
normalizedBackgroundEffort = (backgroundEffort - mean(backgroundEffort)) / std(backgroundEffort);

% Create the parametric modulator structure
pmod(1).name = {'backgroundEffort'};
pmod(1).param = {normalizedBackgroundEffort};
pmod(1).poly = {1};
pmod(1).orth = 0;  % Set orthogonalization to 0

% Add empty pmod structures for the other conditions
pmod(2).name = {};
pmod(2).param = {};
pmod(2).poly = {};
% pmod(2).orth = 0;  % Set orthogonalization to 0
pmod(3).name = {};
pmod(3).param = {};
pmod(3).poly = {};
% pmod(3).orth = 0;  % Set orthogonalization to 0

% Save the data to a .mat file in the same folder as the CSV files
save(fullfile(subjectFolder, 'conditions_onsets_background_effort_pmod.mat'), 'names', 'onsets', 'durations', 'pmod');

disp('The .mat file has been created successfully.');
