%%% Figure 1 AET paper - task schematics
% Emma Scholey 25 Nov 2024

clearvars; close all
addpath('./functions')

run figure_properties_aet.m

save_figs = 1;

%% PANEL: offer distributions per environment

figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square./[1 1 1.1 1.5]);
h = bar([1/2, 1/6; 1/3, 1/3; 1/6, 1/2]);

ylabel('p(encounter)')
xticklabels({'low effort', 'mid effort', 'high effort'})
yticks([0:0.25:0.5])

h(1).FaceColor = colour.easy; h(1).EdgeColor = colour.easy;% low effort environment
h(2).FaceColor = colour.hard; h(2).EdgeColor = colour.hard;% high effort environment

%legend({'easy environment', 'hard environment'})

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
if save_figs == 1
    print([export_path, 'fig1_env_distributions'],'-dsvg')
end

%% PANEL: hypothesis results figure
figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square./[1 1 1.2 1.5]);

data = [1, 1; 0, 1; 0, 0];
minHeight = 0.02;  % adjust to taste

h = bar(max(data, minHeight));

ylabel('pr(accept)')
xticklabels({'low effort', 'mid effort', 'high effort'})
yticks([0:0.5:1])

h(1).FaceColor = colour.easy; h(1).EdgeColor = colour.easy;% low effort environment
h(2).FaceColor = colour.hard; h(2).EdgeColor = colour.hard;% high effort environment

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
if save_figs == 1
    print([export_path, 'fig1_hypothesis'],'-dsvg')
end

%% PANEL: average effort rate per environment 

% % moving window of 20 encounters
% figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);
% hold on
% 
% load ../task/Task_script_AET_mri/blocks/high_1.mat
% hard_avg_effort = movmean(block(:,2), 20);
% load ../task/Task_script_AET_mri/blocks/low_1.mat
% easy_avg_effort = movmean(block(:,2), 20);
% 
% plot(hard_avg_effort, 'LineWidth',widths.plot, 'color',colour.hard);
% plot(easy_avg_effort, 'LineWidth',widths.plot, 'color',colour.easy)
% ylim([0,0.6]), xlim([0 60])
% xticks([0 60]), xticklabels({'0', '300'})
% ylabel('Effort rate')
% xlabel('Time (s)')
% 
% FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
% if save_figs == 1
%     print([export_path, 'fig1_avg_eff_rate_per_env'],'-dsvg')
% end

%% PANEL: average effort rate over blocks

y_hard = 2.7;
y_easy = 1.33;

% moving window of 20 encounters
figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square./[1 1 1.2 1.5]);
hold on

load ../data/behavioural/mri/behav_summary_mri.mat

example_data = results{1};
moving_avg_effort = movmean(example_data.effort/111, 10);

colour.hard = [216 95 89] / 255;
colour.easy = [60 107 157] / 255;

x_hard1 = [1 48];   
x_easy1 = [49 92]; 
x_hard2 = [93 143];   
x_easy2 = [144 184]; 
x_hard3 = [227 281];   
x_easy3 = [185 226]; 

% Draw horizontal lines
plot(x_hard1, [y_hard y_hard], 'Color', colour.hard, 'LineWidth', 4);
plot(x_easy1, [y_easy y_easy], 'Color', colour.easy, 'LineWidth', 4);
plot(x_hard2, [y_hard y_hard], 'Color', colour.hard, 'LineWidth', 4);
plot(x_easy2, [y_easy y_easy], 'Color', colour.easy, 'LineWidth', 4);
plot(x_hard3, [y_hard y_hard], 'Color', colour.hard, 'LineWidth', 4);
plot(x_easy3, [y_easy y_easy], 'Color', colour.easy, 'LineWidth', 4);

plot(moving_avg_effort, 'k', 'LineWidth',1);
ylim([0,3])
ylabel('effort rate')
xlabel('trial')
%xticks([0:150:300]), xticklabels({''})

FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
if save_figs == 1
    print([export_path, 'fig1_avg_eff_rate_across_task'],'-dsvg')
end

