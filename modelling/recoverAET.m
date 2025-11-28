%% ---- Script to recover AET model for predator-prey task ---- %%
% Emma Scholey
% latest update 14 August 2023

clear
close all

addpath('./helperFunctions')
addpath('../../figures/functions/')

run figure_properties_aet.m

%% user options

% model options
%modelNum = 6; % model type - see model table to check number to choose
modelNum = 107; % model type - see model table to check number to choose

%modelTable = readtable('./AETModelTable_final.xlsx'); 
modelTable = readtable('./AETModelTable_new.xlsx'); 


%% set up

funcOptions.version = 'mri';

% simulation options
funcOptions.type = 'simulate_new'; % 'simulate_new' if simulating new parameters, 'simulate_fit' if simulating already fit parameters for each subject
funcOptions.nSim = 100;

% load task
task = buildTask(funcOptions); % set up task

% load dataframe container for simulations
allData = buildData(funcOptions);

% load model
model = table2struct(modelTable(modelTable.modelNumber == modelNum,:));

% load agent parameters 
funcOptions.type = 'recover'; % we want to generate new parameters from scratch, not load existing. Temporarily change flag.
%allParams = buildParams(model,funcOptions); clear params
allParams = buildParams_new(model,funcOptions); clear params

model.paramNames = allParams.names;

funcOptions.type = 'simulate_new'; % revert back 

%% run simulations

for iS = 1:funcOptions.nSim

        iS

        agentParams = allParams.params{iS,:};
        agent.data = allData.data{iS}; 
        agent.blockOrder = allData.blockOrder(iS,:);

        %[~,results] = simulate_AET_task(task,model,agent,agentParams);
        [~,results] = simulate_AET_task_new(task,model,agent,agentParams);


        for iB = 1:6 % each block
            simData.data{iS}{iB} = table2array(results(results.blockNumber == iB,{'response', 'effortLevel', 'realEffort','blockType', 'reward'}));
        end
        simData.nObservations(iS) = sum(results.response ~= 8888);
end

%% fit back to the simulated data 
funcOptions.type = 'fit'; % 'simulate_new' if simulating new parameters, 'simulate_fit' if simulating already fit parameters for each subject
funcOptions.nSim = 1; % how many search points 

% load random set of start parameters for fmincon search
%searchParams = buildParams(model,funcOptions);
searchParams = buildParams_new(model,funcOptions);

paramArray = table2array(searchParams.params);

options = optimoptions('fmincon','Display','none'); % don't display
lb = searchParams.lb;
ub = searchParams.ub;

% initialise containers
minNLLFitParams_recovered = zeros([allData.nSim allParams.nParams]);

for iS = 1:allData.nSim

    iS

    agent.data = simData.data{iS};
    agent.blockOrder = allData.blockOrder(iS,:);

    NLLEval = zeros([funcOptions.nSim, 1]);
    FitParams = zeros([funcOptions.nSim, allParams.nParams]);

    % Run fmincon
    parfor ii = 1:funcOptions.nSim
        params0 =  paramArray(ii,:);

        %f = @(x0)simulate_AET_task(task,model,agent,x0);
        f = @(x0)simulate_AET_task_new(task,model,agent,x0);

        [FitParams(ii,:),NLLEval(ii)] = fmincon(f,params0,[],[],[],[],lb,ub,[],options);
    end

    % Find the best fitting parameter values
    minNLL = min(NLLEval);   % minimum negative log likelihood over all starting positions
    ix = find(minNLL == NLLEval);    % indices of location of minimum, to find the corresponding best fit parameters
    minNLLFitParams_recovered(iS,:) = FitParams(ix(1),:); % get corresponding parameter values at lowest NLL

end

%% plots
close all

figure; tl = tiledlayout('flow', 'TileSpacing', 'Compact');

for i= 1:allParams.nParams
    nexttile;
    scatter(allParams.params{:,i},minNLLFitParams_recovered(:,i))
    
    xlabel(['Simulated ' , model.paramNames{i}])
    ylabel(['Fit ' , model.paramNames{i}])
    model.paramNames{i}

    corr([allParams.params{:,i}, minNLLFitParams_recovered(:,i)], 'type', 'Spearman')
end


% plot trade off between parameters 
if allParams.nParams > 1
    combinations = nchoosek(1:allParams.nParams,2);
    figure; tl = tiledlayout('flow', 'TileSpacing', 'Compact');

    for i= 1:size(combinations,1)
        nexttile;
        scatter(minNLLFitParams_recovered(:,combinations(i,1)),minNLLFitParams_recovered(:,combinations(i,2)))
        xlabel(sprintf('Fit %s', model.paramNames{:,combinations(i,1)}))
        ylabel(sprintf('Fit %s', model.paramNames{:,combinations(i,2)}))

       disp(model.paramNames{:,combinations(i,1)})
       disp(model.paramNames{:,combinations(i,2)})
       [r, p] = corr(minNLLFitParams_recovered(:,combinations(i,1)),minNLLFitParams_recovered(:,combinations(i,2)), 'type', 'Spearman');
    end
end


%% plot heatmap
r = corr(table2array(allParams.params),minNLLFitParams_recovered, type="Spearman");
r = round(r,2);
figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);
h = heatmap(r,'MissingDataColor','w', 'GridVisible', 'off', 'ColorLimits',[-1,1]);
colormap(brewermap([], 'RdBu'));

%labels = ["\kappa","\beta","\alpha"];
labels = ["\kappa_1","\beta","\omega", '\alpha'];

h.XDisplayLabels = labels;
h.YDisplayLabels = labels; 
h.XLabel = 'simulated';
h.YLabel = 'estimated';
set(gca,'FontSize',fontsize)

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
%print([sprintf('../../figures/panels/parameter_recovery_M%d_',modelNum), funcOptions.version],'-dsvg')
