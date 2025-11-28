clear all

% Prompt the user to enter the subject number
subjectNumber = input('Enter the subject number (single digit values should have a leading 0, e.g., 02): ', 's');

% Construct the file paths based on the entered subject number
baseFolder = '/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/';
subjectFolder = fullfile(baseFolder, ['sub-', subjectNumber]);
cueOnsetsPath = fullfile(subjectFolder, 'cueOnsets.csv');
exertOnsetsPath = fullfile(subjectFolder, 'exertOnsets.csv');
feedbackOnsetsPath = fullfile(subjectFolder, 'feedbackOnsets.csv');
modelEstimatesPath = fullfile(subjectFolder, 'model_estimates_M37.csv');

% Read the CSV files to get the onsets
cueOnsets = csvread(cueOnsetsPath);
exertOnsets = csvread(exertOnsetsPath);
feedbackOnsets = csvread(feedbackOnsetsPath);

% Read the model estimates CSV file to get the backgroundEffort values
modelEstimates = readtable(modelEstimatesPath);
predictionErr = modelEstimates.effortPE;

% Create cell arrays for names, onsets, and durations
names = {'cueOnset', 'exertOnset', 'feedbackOnset'};
onsets = {cueOnsets, exertOnsets, feedbackOnsets};
durations = {zeros(size(cueOnsets)), zeros(size(exertOnsets)), zeros(size(feedbackOnsets))};

% Normalize the backgroundEffort values
normalizedpredictionErr = (predictionErr - mean(predictionErr)) / std(predictionErr);

% Create the parametric modulator structure
pmod(1).name = {'predictionErr'};
pmod(1).param = {normalizedpredictionErr};
pmod(1).poly = {1};
pmod(1).orth = 0;  % Set orthogonalization to 0

% Add empty pmod structures for the other conditions
pmod(2).name = {};
pmod(2).param = {};
pmod(2).poly = {};
pmod(3).name = {};
pmod(3).param = {};
pmod(3).poly = {};

% Save the data to a .mat file in the same folder as the CSV files
save(fullfile(subjectFolder, 'conditions_onsets_effortPE_pmod.mat'), 'names', 'onsets', 'durations', 'pmod');

disp('The .mat file has been created successfully.');
