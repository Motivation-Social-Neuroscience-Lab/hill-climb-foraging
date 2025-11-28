%% ---- Script to simulate effort tracking task ---- %%
% Emma Scholey
% latest update 17 August 2023

clear
close all

addpath('./helperFunctions')

%% user options
nRun = 50; % how many iterations to simulate for each agent
save_data = 0; % flag to save data (1) or not (0)

% model options
modelNum = [101:103]; % model type - see model table to check number to choose
%modelTable = readtable('./AETModelTable_final.xlsx');
modelTable = readtable('./AETModelTable_new.xlsx');

% simulation options
simOptions.type = 'simulate_fit'; % 'simulate_new' if simulating new parameters, 'simulate_fit' if simulating already fit parameters for each subject
simOptions.version = 'mri'; % data version, either v1, v3, or mri

% options below will override if simulating already fit parameters
simOptions.nSim = 50;

switch simOptions.version
    case 'v1'
        simOptions.params = [0.55124, 0, 1.5512, 1, 0.92077]; % {'kOffer','k', 'beta_one', 'beta_two', 'alpha', 'weight'};
    case 'v3'
        simOptions.params = [0.46, 0, 1.78, 1, 0.0269]; % {'kOffer','k', 'beta_one', 'beta_two', 'alpha', 'weight'};
    case 'mri'
        %simOptions.params = [1.73, 0, 1.68, 1, 0.014]; % {'kOffer','k', 'beta_one', 'beta_two', 'alpha', 'weight'};
        simOptions.params = [0.32, 0, 4.2, 1, 0.09, 0.20]; % {'kOffer','k', 'beta_one', 'beta_two', 'alpha', 'weight'};

end
%% set up
% load task
task = buildTask(simOptions); % set up task

% load model
model = table2struct(modelTable(modelTable.modelNumber == modelNum,:));

% load agent parameters
allParams = buildParams(model,simOptions); clear params
%allParams = buildParams_new(model,simOptions); clear params

model.paramNames = allParams.names;

% load dataframe container for simulations
allData = buildData(simOptions);

%% run simulations
run_acceptRate = zeros([allData.nSim, numel(task.effortLevels), numel(task.env), nRun]);
run_offerValue = zeros([allData.nSim, numel(task.effortLevels), numel(task.env), nRun]);

out = {};

for iR = 1:nRun

    iR

    for iS = 1:allData.nSim

        agentParams = allParams.params{iS,:};
        agent.data = allData.data{iS};
        agent.blockOrder = allData.blockOrder(iS,:);

        [NLL,results] = simulate_AET_task(task,model,agent,agentParams);
        %[NLL,results] = simulate_AET_task_new(task,model,agent,agentParams);

        results.subjectNumber = repelem(iS, size(results,1))';
        simData{iS} = results;

    end

    % compute variables of interest from simulated data
    acceptRate = zeros([allData.nSim, numel(task.effortLevels), numel(task.env)]);
    offerValue = zeros([allData.nSim, numel(task.effortLevels), numel(task.env)]);
    backgroundEffort = zeros([allData.nSim, numel(task.env)]);
    effortPE = zeros([allData.nSim, numel(task.effortLevels), numel(task.env)]);

    for iS = 1:allData.nSim
        % Extract acceptance rates for each offer and environment
        for iEnv = 1:numel(task.env) % environment
            backgroundEffort(iS,iEnv) = mean(simData{iS}.backgroundEffort(simData{iS}.blockType == task.env(iEnv)));
            for iOffer = 1:numel(task.effortLevels) % offer
                acceptRate(iS,iOffer,iEnv) = mean(simData{iS}.response(simData{iS}.effortLevel == task.effortLevels(iOffer) & simData{iS}.blockType == task.env(iEnv)));
                offerValue(iS,iOffer,iEnv) = mean(simData{iS}.predictedValue(simData{iS}.effortLevel == task.effortLevels(iOffer) & simData{iS}.blockType == task.env(iEnv)));
                effortPE(iS,iOffer,iEnv) = mean(simData{iS}.effortPE(simData{iS}.effortLevel == task.effortLevels(iOffer) & simData{iS}.blockType == task.env(iEnv)));

            end

        end
    end

    run_acceptRate(:,:,:,iR) = acceptRate;
    run_offerValue(:,:,:,iR) = offerValue;

    out = vertcat(out, vertcat(simData{:}));
end

%% save dataframe for analysis and plotting in R 

% add response history (whether they accept/reject on previous trial)
out{2:end, 'responseHistory'} = out{1:end-1, 'response'};
out{out.trialNinBlock == 1, 'responseHistory'} = 0;

% add effort history (what effort they exerted on the previous trial)
out{2:end, 'exertedEffortHistory'} = out{1:end-1,'realEffort'};
out{out.trialNinBlock == 1, 'exertedEffortHistory'} = 0;

% add effort history (what effort they saw on the previous trial)
out{2:end, 'effortHistory'} = out{1:end-1,'effortLevel'};
out{out.trialNinBlock == 1, 'effortHistory'} = 2;


if modelNum == 5 & save_data == 1% if winning model, save simulations for plotting
    %writematrix(mean_accept_across_runs,sprintf('../../data_derived/%s/simulated_accept_rate_M%d.csv', simOptions.version, modelNum));
    writetable(out,sprintf('../../data_derived/%s/behav_summary_M%d_%s.csv', simOptions.version, modelNum, simOptions.version));
end

%% plot to show expected p(accept) results

mean_accept_across_runs = mean(run_acceptRate, 4);
meanAcceptRate = squeeze(mean(mean_accept_across_runs));

figure
h = bar(meanAcceptRate);
hold on
h(1).FaceColor = '#46B8DA'; h(1).EdgeColor = '#46B8DA';% low effort environment
h(2).FaceColor = '#D43F3A'; h(2).EdgeColor = '#D43F3A';% high effort environment
% plot individual data points
[m,n] = size(meanAcceptRate);
for i = 1:m
    for j = 1:n
        s = scatter(repmat(h(j).XEndPoints(i), allData.nSim, 1),mean_accept_across_runs(:,i,j),40,'MarkerFaceColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2,'MarkerEdgeColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2, 'LineWidth',1,'XJitter','randn','XJitterWidth',.05);
    end
end

ylim([0,1])
xticklabels({'low', 'mid', 'high'});
ylabel('Proportion accepted');
legend('Low effort', 'High effort');
set(findall(gcf,'-property','FontSize'),'FontSize',18)

%% plot to show offer value for each offer x environment
mean_value_across_runs = mean(run_offerValue, 4);
meanOfferValue = squeeze(mean(mean_value_across_runs));

figure
h = bar(meanOfferValue);
hold on
h(1).FaceColor = '#46B8DA'; h(1).EdgeColor = '#46B8DA';% low effort environment
h(2).FaceColor = '#D43F3A'; h(2).EdgeColor = '#D43F3A';% high effort environment
% plot individual data points
[m,n] = size(meanOfferValue);
for i = 1:m
    for j = 1:n
        s = scatter(repmat(h(j).XEndPoints(i), allData.nSim, 1),mean_value_across_runs(:,i,j),40,'MarkerFaceColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2,'MarkerEdgeColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2, 'LineWidth',1,'XJitter','randn','XJitterWidth',.05);
    end
end

xticklabels({'low', 'mid', 'high'});
ylabel('Offer value');
legend('Low effort', 'High effort');
set(findall(gcf,'-property','FontSize'),'FontSize',18)


%% plot to show change in background effort

figure; tl = tiledlayout('flow', 'TileSpacing', 'Compact');
for iS = 1:allData.nSim
    backgroundEffortTrend= simData{iS}.backgroundEffort;
    nexttile
    plot(backgroundEffortTrend)

    % if strcmp(model.discountFunction, 'effort')
    %     ylim([0, 3])
    % else
    %     ylim([0 1])
    % end
end
xlabel('Trial')
ylabel('Background effort estimate')
set(findall(gcf,'-property','FontSize'),'FontSize',18)

%% plot to show effort prediction error

figure
h = bar(squeeze(mean(effortPE)));
hold on
h(1).FaceColor = '#46B8DA'; h(1).EdgeColor = '#46B8DA';% low effort environment
h(2).FaceColor = '#D43F3A'; h(2).EdgeColor = '#D43F3A';% high effort environment
% plot individual data points
[m,n] = size(meanAcceptRate);
for i = 1:m
    for j = 1:n
        s = scatter(repmat(h(j).XEndPoints(i), allData.nSim, 1),effortPE(:,i,j),40,'MarkerFaceColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2,'MarkerEdgeColor',h(j).FaceColor+(1-h(j).FaceColor) * 0.2, 'LineWidth',1,'XJitter','randn','XJitterWidth',.05);
    end
end

%ylim([0,1])
xticklabels({'low', 'mid', 'high'});
ylabel('Mean effort PE');
legend('Low effort', 'High effort', 'Location','northwest');
set(findall(gcf,'-property','FontSize'),'FontSize',18)

%% plot to show LL over time
% 
% figure
% for iS = 1:allData.nSim
%     nexttile
%     plot(simLL{iS})
%     ylim([-150, 0])
% end
% 
% figure
% for iS = 1:allData.nSim
%     nexttile
%     hist(simData{iS}.pSelected)
%     ylim([0,200])
% end
% 
% 
% figure, scatter(allParams.params.kOffer,cellfun(@min,simLL)), title('k'), [c p ] = corr(allParams.params.kOffer,cellfun(@min,simLL)')
% figure, scatter(log(allParams.params.beta_one),cellfun(@min,simLL)), title('beta'), [c p ] = corr(log(allParams.params.beta_one),cellfun(@min,simLL)')
% figure, scatter(log(allParams.params.alpha),cellfun(@min,simLL)), title('alpha'), [c p ] = corr(log(allParams.params.alpha),cellfun(@min,simLL)')
% 
% % beta is strongly positively correlated
% figure, hist(allParams.params.beta_one)
% 
