%% ---- Script to recover AET model for predator-prey task - model identifiability ---- %%
% Emma Scholey
% latest update 14 August 2023

clear
close all

addpath('./helperFunctions')
addpath('../../figures/functions/')

run figure_properties_aet.m

%% user options

% model options
modelNum = [1,3]; % model type - see model table to check number to choose
modelTable = readtable('./AETModelTable_final.xlsx');

%% set up

funcOptions.version = 'mri';

for iM = 1:numel(modelNum)

    % simulation options
    funcOptions.type = 'simulate_new'; % 'simulate_new' if simulating new parameters, 'simulate_fit' if simulating already fit parameters for each subject
    funcOptions.nSim = 100;
    % load task
    task = buildTask(funcOptions); % set up task

    % load dataframe container for simulations
    allData = buildData(funcOptions);

    % load model
    model = table2struct(modelTable(modelTable.modelNumber == modelNum(iM),:));

    % load agent parameters
    funcOptions.type = 'recover'; % we want to generate new parameters from scratch, not load existing. Temporarily change flag.
    allParams = buildParams(model,funcOptions); clear params
    model.paramNames = allParams.names;

    funcOptions.type = 'simulate_new'; % revert back

    %% run simulations

    for iS = 1:funcOptions.nSim

        agentParams = allParams.params{iS,:};
        agent.data = allData.data{iS};
        agent.blockOrder = allData.blockOrder(iS,:);

        [~,results] = simulate_AET_task(task,model,agent,agentParams);

        for iB = 1:6 % each block
            simData.data{iS}{iB} = table2array(results(results.blockNumber == iB,{'response', 'effortLevel', 'realEffort','blockType', 'reward'}));
        end
        simData.nObservations(iS) = sum(results.response ~= 8888);
    end

    %% fit all models back to the simulated data

    for jM = 1:numel(modelNum)

        model = table2struct(modelTable(modelTable.modelNumber == modelNum(jM),:));
        funcOptions.type = 'fit'; % 'simulate_new' if simulating new parameters, 'simulate_fit' if simulating already fit parameters for each subject
        funcOptions.nSim = 5; % how many search points

        % load random set of start parameters for fmincon search
        searchParams = buildParams(model,funcOptions);
        model.paramNames = searchParams.names;
        paramArray = table2array(searchParams.params);

        options = optimoptions('fmincon','Display','none'); % don't display
        lb = searchParams.lb;
        ub = searchParams.ub;

        for iS = 1:allData.nSim

            disp(num2str([modelNum(iM),modelNum(jM), iS]))

            agent.data = simData.data{iS};
            agent.blockOrder = allData.blockOrder(iS,:);

            NLLEval = zeros([funcOptions.nSim, 1]);
            FitParams = zeros([funcOptions.nSim, searchParams.nParams]);

            % Run fmincon
            parfor ii = 1:funcOptions.nSim
                params0 =  paramArray(ii,:);

                f = @(x0)simulate_AET_task(task,model,agent,x0);
                [FitParams(ii,:),NLLEval(ii)] = fmincon(f,params0,[],[],[],[],lb,ub,[],options);
            end

            % Find the best fitting parameter values
            minNLL = min(NLLEval);   % minimum negative log likelihood over all starting positions
            BIC(iS,jM) = searchParams.nParams * log(simData.nObservations(iS)) + 2*minNLL;

        end

        model_BIC(jM) = sum(BIC(:,jM));
    end 


    posteriorProbabilities = BICposterior(BIC);
    [~, ~, exceedance_probabilities(iM,:), protected_XP(iM,:)] = spm_BMS(posteriorProbabilities);

end
modelNames = {'1\kappa 1\beta', '1\kappa 2\beta','\tau 1\kappa 1\beta', '\tau 2\kappa 1\beta', '\tau 1\kappa 2\beta'};

exceedance_probabilities = round(exceedance_probabilities,2)';
%save(sprintf('../../data_derived/%s/fitting/XP_model_identifiability', funcOptions.version), 'exceedance_probabilities','protected_XP', 'modelNames')

%% plot heatmap

load(sprintf('../../data_derived/%s/fitting/XP_model_identifiability', funcOptions.version), 'exceedance_probabilities','protected_XP', 'modelNames')
modelNames = {'1\kappa 1\beta', '1\kappa 2\beta','\tau 1\kappa 1\beta', '\tau 2\kappa 1\beta', '\tau 1\kappa 2\beta'};

figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);
h = heatmap(exceedance_probabilities,'MissingDataColor','w', 'ColorMap', sky, 'GridVisible', 'off','CellLabelColor','none');
labels = modelNames;
h.XDisplayLabels = labels;
h.YDisplayLabels = labels;
h.XLabel = 'simulated';
h.YLabel = 'estimated';
set(gca,'FontSize',fontsize)

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
print(['../../figures/panels/model_identifiability_', funcOptions.version],'-dsvg')


