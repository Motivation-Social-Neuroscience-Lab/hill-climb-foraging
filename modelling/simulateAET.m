%% ---- Script to simulate effort tracking task ---- %%
% Emma Scholey
% latest update 19 November 2025

clear
close all

addpath('./helperFunctions')

%% user options
save_data = 0; % flag to save data (1) or not (0)

% model options
modelNum = 13; % model type - see model table to check number to choose

study_version = 'mri';

param_type = 'fit'; % which parameters to simulate {uniform, fit, median}
nsims = 500; % number of simulated participants (doesn't apply if using 'fit' parameters)

fit_type = 'MAP'; % MLE or MAP fitting

%% SET UP --------------------------------------------------------------
% load study settings
fit_flag = 0;
config = config_study(study_version, fit_flag);

% load fit parameters

switch fit_type
    case 'MAP'
        load([config.paths.data_fit, 'fitting_hierarchical_M' num2str(modelNum)]);
    case 'MLE'
        load([config.paths.data_fit, 'fitting_MLE_M' num2str(modelNum)]);
end

% load and prepare dataframe container for simulations
behav_data = buildData(config, fit_flag, nsims);

switch param_type
    case 'uniform'
        params = min(modout.fitted_params_real,[],2) + (max(modout.fitted_params_real,[],2) - min(modout.fitted_params_real,[],2)) .* rand(height(modout.fitted_params_real), nsims); %uniform distribution bounded by min/max of real data
    case 'fit'
        params = modout.fitted_params_real; %simulate each subject once with their estimate
        nsims = modout.nsubj;
    case 'median'
        params = repmat(median(modout.fitted_params_real,2), [1, nsims]); %simulate median of fit parameters
end

%% SIMULATIONS ------------------------------------------------------------

% Simulate and fit X number of times
simdata = cell(1, nsims);

for isub = 1:nsims

    agent = behav_data{randi(numel(behav_data))}; %grab the trial order from a random participant each loop (shouldn't really matter, but do just in case)

    [~, simdata{isub}] = simulate_AET_model(config.task, modout.model, agent, params(:, isub)');

end

[results,out] = summarise_simulated(simdata, config);

if save_data == 1% save simulations for further analysis in R
    writetable(out,[config.paths.data_behav, sprintf('cleaned_behav_summary_M%d_%s.csv', modelNum, study_version)]);
    param_table = array2table(modout.fitted_params_real', 'VariableNames',modout.param_names);
    writetable(param_table,[config.paths.data_fit, sprintf('fit_params_M%d.csv', modelNum)]);
end

%% PLOTS -----------------------------------------------------------------
figure;
tl = tiledlayout('flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');

% Subplot 1: Accept Rate
nexttile
h1 = bar(results.acceptRate.mean);
hold on
h1(1).FaceColor = '#46B8DA'; h1(1).EdgeColor = '#46B8DA'; % low effort environment
h1(2).FaceColor = '#D43F3A'; h1(2).EdgeColor = '#D43F3A'; % high effort environment
% Add individual data points
[m, n] = size(results.acceptRate.mean);
for i = 1:m
    for j = 1:n
        scatter(repmat(h1(j).XEndPoints(i), size(results.acceptRate.raw, 1), 1), ...
            results.acceptRate.raw(:, i, j), 40, ...
            'MarkerFaceColor', h1(j).FaceColor + (1 - h1(j).FaceColor) * 0.2, ...
            'MarkerEdgeColor', h1(j).FaceColor + (1 - h1(j).FaceColor) * 0.2, ...
            'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
    end
end
ylim([0, 1])
xticklabels({'low', 'mid', 'high'});
ylabel('Accept Rate');
legend('Low effort env', 'High effort env', 'Location', 'best');
title('Accept Rate');
set(gca, 'FontSize', 14)

% Subplot 2: Value
nexttile
h2 = bar(results.offerValue.mean);
hold on
h2(1).FaceColor = '#46B8DA'; h2(1).EdgeColor = '#46B8DA';
h2(2).FaceColor = '#D43F3A'; h2(2).EdgeColor = '#D43F3A';
for i = 1:m
    for j = 1:n
        scatter(repmat(h2(j).XEndPoints(i), size(results.offerValue.raw, 1), 1), ...
            results.offerValue.raw(:, i, j), 40, ...
            'MarkerFaceColor', h2(j).FaceColor + (1 - h2(j).FaceColor) * 0.2, ...
            'MarkerEdgeColor', h2(j).FaceColor + (1 - h2(j).FaceColor) * 0.2, ...
            'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
    end
end
xticklabels({'low', 'mid', 'high'});
ylabel('Value');
legend('Low effort env', 'High effort env', 'Location', 'best');
title('Offer Value');
set(gca, 'FontSize', 14)

% Subplot 3: Background Effort
nexttile
h3 = bar(results.background.mean);
hold on
h3(1).FaceColor = '#46B8DA'; h3(1).EdgeColor = '#46B8DA';
h3(2).FaceColor = '#D43F3A'; h3(2).EdgeColor = '#D43F3A';
for i = 1:m
    for j = 1:n
        scatter(repmat(h3(j).XEndPoints(i), size(results.background.raw, 1), 1), ...
            results.background.raw(:, i, j), 40, ...
            'MarkerFaceColor', h3(j).FaceColor + (1 - h3(j).FaceColor) * 0.2, ...
            'MarkerEdgeColor', h3(j).FaceColor + (1 - h3(j).FaceColor) * 0.2, ...
            'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
    end
end
xticklabels({'low', 'mid', 'high'});
ylabel('Background Effort');
legend('Low effort env', 'High effort env', 'Location', 'best');
title('Background Effort');
set(gca, 'FontSize', 14)

% Subplot 4: Effort PE
nexttile
h4 = bar(results.effortPE.mean);
hold on
h4(1).FaceColor = '#46B8DA'; h4(1).EdgeColor = '#46B8DA';
h4(2).FaceColor = '#D43F3A'; h4(2).EdgeColor = '#D43F3A';
for i = 1:m
    for j = 1:n
        scatter(repmat(h4(j).XEndPoints(i), size(results.effortPE.raw, 1), 1), ...
            results.effortPE.raw(:, i, j), 40, ...
            'MarkerFaceColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
            'MarkerEdgeColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
            'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
    end
end
xticklabels({'low', 'mid', 'high'});
ylabel('Effort PE');
legend('Low effort env', 'High effort env', 'Location', 'best');
title('Effort Prediction Error');
set(gca, 'FontSize', 14)

sgtitle('Metrics by Environment and Effort Level', 'FontSize', 16, 'FontWeight', 'bold')

% % Subplot 5: Reward PE
% nexttile
% h4 = bar(results.rewardPE.mean);
% hold on
% h4(1).FaceColor = '#46B8DA'; h4(1).EdgeColor = '#46B8DA';
% h4(2).FaceColor = '#D43F3A'; h4(2).EdgeColor = '#D43F3A';
% for i = 1:m
%     for j = 1:n
%         scatter(repmat(h4(j).XEndPoints(i), size(results.rewardPE.raw, 1), 1), ...
%             results.rewardPE.raw(:, i, j), 40, ...
%             'MarkerFaceColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
%             'MarkerEdgeColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
%             'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
%     end
% end
% xticklabels({'low', 'mid', 'high'});
% ylabel('Reward PE');
% legend('Low effort env', 'High effort env', 'Location', 'best');
% title('Reward Prediction Error');
% set(gca, 'FontSize', 14)
% 
% % Subplot 6: Background reward
% nexttile
% h4 = bar(results.backgroundRew.mean);
% hold on
% h4(1).FaceColor = '#46B8DA'; h4(1).EdgeColor = '#46B8DA';
% h4(2).FaceColor = '#D43F3A'; h4(2).EdgeColor = '#D43F3A';
% for i = 1:m
%     for j = 1:n
%         scatter(repmat(h4(j).XEndPoints(i), size(results.backgroundRew.raw, 1), 1), ...
%             results.backgroundRew.raw(:, i, j), 40, ...
%             'MarkerFaceColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
%             'MarkerEdgeColor', h4(j).FaceColor + (1 - h4(j).FaceColor) * 0.2, ...
%             'LineWidth', 1, 'XJitter', 'randn', 'XJitterWidth', 0.05);
%     end
% end
% xticklabels({'low', 'mid', 'high'});
% ylabel('Background Reward');
% legend('Low effort env', 'High effort env', 'Location', 'best');
% title('Background reward rate');
% set(gca, 'FontSize', 14)
% 
% sgtitle('Metrics by Environment and Effort Level', 'FontSize', 16, 'FontWeight', 'bold')


%% Plot trajectories for participants

% Figure: Background Effort Rate
figure;
tl2 = tiledlayout('flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:modout.nsubj % if simulating more agents than subjects, just take the same n as fitted subjects 
    nexttile
    validTrials = ~isnan(results.trajectories.background(i, :));
    plot(results.trajectories.time(validTrials), ...
        results.trajectories.background(i, validTrials), ...
        'LineWidth', 1.5, 'Color', 'r');
    if mod(i, 2) == 1
        ylabel('bE');
    end
    ylim([1.5, 2.5])
    set(gca, 'FontSize', 12)
    grid on
end

sgtitle('Background Effort Rate Over Trials', 'FontSize', 16, 'FontWeight', 'bold')

% Figure: Opp Cost Rate
figure;
tl3 = tiledlayout('flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:modout.nsubj % if simulating more agents than subjects, just take the same n as fitted subjects 
    nexttile
    validTrials = ~isnan(results.trajectories.oppCost(i, :));
    plot(results.trajectories.time(validTrials), ...
        results.trajectories.oppCost(i, validTrials), ...
        'LineWidth', 1.5, 'Color', 'r');
    if mod(i, 2) == 1
        ylabel('Opp Cost');
    end
    %ylim([-0.6,0.6])
    set(gca, 'FontSize', 12)
    grid on
end

sgtitle('Opportunity Cost Rate Over Trials', 'FontSize', 16, 'FontWeight', 'bold')


% % Figure: Background Reward Rate
% figure;
% tl2 = tiledlayout('flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');
% 
% for i = 1:modout.nsubj % if simulating more agents than subjects, just take the same n as fitted subjects 
%     nexttile
%     validTrials = ~isnan(results.trajectories.backgroundRew(i, :));
%     plot(results.trajectories.time(validTrials), ...
%         results.trajectories.backgroundRew(i, validTrials), ...
%         'LineWidth', 1.5, 'Color', 'r');
%     if mod(i, 2) == 1
%         ylabel('Background Reward Rate');
%     end
%     set(gca, 'FontSize', 12)
%     grid on
% end
% 
% sgtitle('Background Reward Rate Over Trials', 'FontSize', 16, 'FontWeight', 'bold')


% Figure: parameter distributions
figure;
tl2 = tiledlayout('flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:modout.npar 
    nexttile
    histogram(modout.fitted_params_real(i,:))
    xlabel(modout.param_names{i})
    if mod(i, 2) == 1
        ylabel('N subjects');
    end
    set(gca, 'FontSize', 12)
    grid on
end

sgtitle('Parameter distributions', 'FontSize', 16, 'FontWeight', 'bold')
