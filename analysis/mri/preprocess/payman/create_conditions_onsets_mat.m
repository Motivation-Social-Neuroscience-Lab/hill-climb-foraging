clear all

% Prompt the user to enter the subject number
subj_num = input('Enter the subject number (single digit values should have a leading 0, e.g., 02): ', 's');

% Construct the file paths based on the entered subject number
baseFolder = '/Users/proghani/Documents/personal/local_thesis_folder/fMRI/main/bids_fmri_data/';
subjectFolder = fullfile(baseFolder, ['sub-', subj_num]);
cueOnsetsPath = fullfile(subjectFolder, 'cueOnsets.csv');
exertOnsetsPath = fullfile(subjectFolder, 'exertOnsets.csv');
feedbackOnsetsPath = fullfile(subjectFolder, 'feedbackOnsets.csv');

% Read the CSV files to get the onsets
cueOnsets = csvread(cueOnsetsPath);
exertOnsets = csvread(exertOnsetsPath);
feedbackOnsets = csvread(feedbackOnsetsPath);

% Create cell arrays for names, onsets, and durations
names = {'cueOnset', 'exertOnset', 'feedbackOnset'};
onsets = {cueOnsets, exertOnsets, feedbackOnsets};
durations = {zeros(size(cueOnsets)), zeros(size(exertOnsets)), zeros(size(feedbackOnsets))};

% Save the data to a .mat file in the same folder as the CSV files
save(fullfile(subjectFolder, 'conditions_onsets.mat'), 'names', 'onsets', 'durations');

disp('The .mat file has been created successfully.');
