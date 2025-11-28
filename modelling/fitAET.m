%% fitting models to foraging data
% Emma Scholey 9 Jun 2022
% latest update 4 August 2023

clear
close all

addpath('./helperFunctions')

modelTable = readtable('./AETModelTable_final.xlsx');
%modelTable = readtable('./AETModelTable_new.xlsx');

%% user options

% model options
modelNum = [5];

% fitting options
fitOptions.type = 'fit'; % not simulati- ng data here
fitOptions.nSim = 4; % how many starts/iterations for fmincon search
fitOptions.version = 'mri'; % what version of the data to model (v1, v3, mri)

%% set up model and task

% load task
task = buildTask(fitOptions);

% load participant data
allData = buildData(fitOptions);
nSub = size(allData.data,2); 

for m = modelNum %modelNum % for all models
    % load model
    model = table2struct(modelTable(modelTable.modelNumber == m,:));

    % load random set of start parameters for fmincon search
    allParams = buildParams(model,fitOptions);
    %allParams = buildParams_new(model,fitOptions);

    model.paramNames = allParams.names;

    %% fitting for each person in group with different starting points
    options = optimoptions('fmincon','Display','none'); % don't display
    lb = allParams.lb;
    ub = allParams.ub;

    % initialise containers
    minNLL = zeros([nSub 1]);
    minNLLFitParams = zeros([nSub allParams.nParams]);
    BIC = zeros([nSub 1]);
    AIC = zeros([nSub 1]);

    paramArray = table2array(allParams.params);

    for iS = 1:nSub

        iS
        agent.data = allData.data{iS};
        agent.blockOrder = allData.blockOrder(iS,:);
        NLLEval = zeros([fitOptions.nSim, 1]);
        FitParams = zeros([fitOptions.nSim, allParams.nParams]);

        %Run fmincon
        parfor ii = 1:fitOptions.nSim
            params0 =  paramArray(ii,:);

            f = @(x0)simulate_AET_task(task,model,agent,x0);
            %f = @(x0)simulate_AET_task_new(task,model,agent,x0);

            [FitParams(ii,:),NLLEval(ii)] = fmincon(f,params0,[],[],[],[],lb,ub,[],options);
        end

        % Find the best fitting parameter values
        minNLL(iS) = min(NLLEval);   % minimum negative log likelihood over all starting positions
        ix = find(minNLL(iS) == NLLEval);    % indices of location of minimum, to find the corresponding best fit parameters
        minNLLFitParams(iS,:) = FitParams(ix(1),:); % get corresponding parameter values at lowest NLL

        % Calculate BIC/AIC
        BIC(iS) = allParams.nParams * log(allData.nObservations(iS)) + 2*minNLL(iS);
        AIC(iS) = 2/allData.nObservations(iS) * minNLL(iS) + 2 * allParams.nParams/allData.nObservations(iS);
    end


    %% plots

        % close all
        % 
        % if allParams.nParams > 1
        %     combinations = nchoosek(1:allParams.nParams,2);
        % 
        % 
        %     figure; tl = tiledlayout('flow', 'TileSpacing', 'Compact');
        % 
        %     for i= 1:size(combinations,1)
        %         nexttile;
        %         scatter(minNLLFitParams(:,combinations(i,1)),minNLLFitParams(:,combinations(i,2)))
        %         xlabel(sprintf('Fit %s', model.paramNames{:,combinations(i,1)}))
        %         ylabel(sprintf('Fit %s', model.paramNames{:,combinations(i,2)}))
        %     end
        % 
        %     title(tl, 'Best fit parameter distributions')
        % else
        %     figure
        %     tl = tiledlayout('flow', 'TileSpacing', 'Compact');
        %     nexttile;
        %     boxchart(minNLLFitParams(:,:))
        %     xlabel(sprintf('Fit %s', model.paramNames{1}))
        % end


    % save results
    medianParams = median(minNLLFitParams);

    minNLLFitParams = array2table(minNLLFitParams, "VariableNames",model.paramNames);
    save_name = sprintf('../../data_derived/%s/fitting/fitting_M%d', fitOptions.version, m);
    save(save_name, 'AIC', 'BIC', 'minNLLFitParams', 'minNLL')

end

