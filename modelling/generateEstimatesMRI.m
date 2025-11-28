%% generating trial-by-trial estimates from computational model for MRI 1st-level GLM
% Emma Scholey 5 April 2024

clear
close all

addpath('./helperFunctions')

modelTable = readtable('./AETModelTable_final.xlsx');

%% user options

% model options
modelNum = ; 

% fitting options
fitOptions.type = 'fit'; % use fitting here to call the simulation script on their real data - we want the number of trials to be exactly the same 
fitOptions.version = 'mri';
%% set up model and task

name_subj = [101:104, 106:110, 112:131, 133:141]; % The file (subject) numbers of the files to be used in the analysis

% load task
task = buildTask(fitOptions);

% load participant data
allData = buildData(fitOptions);

% who do we have? so we cna make folders for them later
matFiles = dir(['../../data_raw/mri/behaviour/main/*MRI.mat']);

%matFiles = 
%save_dir = ['../../data_derived/mri/processed/sub-'];
save_dir = ['/Volumes/appsmaj-motivation-social-neuro/Emma/aet_fMRI/preprocessed/sub-'];

% exclude subjects
for i = 1:length(matFiles)
    ix(i) = ismember(str2double(matFiles(i).name(1:3)), name_subj);
end

matFiles = matFiles(ix);

for m = modelNum % for all models
    % load model
    model = table2struct(modelTable(modelTable.modelNumber == m,:));

    % load all subjects' fitted parameters
    load(sprintf('../../data_derived/mri/fitting/fitting_M%d', model.modelNumber), 'minNLLFitParams');
    %allParams.params = repmat(mean(minNLLFitParams), [allData.nSim, 1]); %uncomment if doing mean parameters 
    allParams.params = minNLLFitParams; 
    allParams.names = allParams.params.Properties.VariableNames;

    model.paramNames = allParams.names;

    %% fitting for each person in group with different starting points

    paramArray = table2array(allParams.params);

    for iS = 1:allData.nSim

        id = matFiles(iS).name(2:3)
       % mkdir([save_dir, id, '/'])

        agent.data = allData.data{iS};
        agent.blockOrder = allData.blockOrder(iS,:);

        [~,results] = simulate_AET_task(task,model,agent,paramArray(iS,:));

        % save results
        writetable(results,[save_dir,id,'/model_estimates_M',num2str(m),'.csv'])

    end

end


mean(tmp)
