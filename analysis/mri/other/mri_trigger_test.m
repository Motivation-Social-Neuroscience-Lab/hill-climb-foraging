%%% Check timing of triggers in AET MRI data
% 13 June 2024
% Emma Scholey


clc
close all
clear all

cd '~/Dropbox/average-effort/data_raw/mri/behaviour/main/' % change as required

matFiles = dir('*MRI.mat');
matFiles = orderfields(matFiles);
tl = tiledlayout('flow');

for i = 1:length(matFiles)

    % load data
    eval(['load ' matFiles(i).name]);

    nexttile
    plot(diff(data.timelog.triggers))

    x(i) = length(data.timelog.triggers);
    ylim([1.24, 1.27])
    yline(1.254), hold on
    text(20,1.264,num2str(data.code), "FontSize",12)
    xlabel('Scan number')
    ylabel('TR (s)')

    % min(diff(data.timelog.triggers))
    % max(diff(data.timelog.triggers))

end
