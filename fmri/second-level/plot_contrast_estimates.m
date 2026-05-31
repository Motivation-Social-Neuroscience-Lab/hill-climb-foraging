%%% Plot contrast estimates for voxels of interest
%%% created 16 June 2025 Emma Scholey for AET analysis

clear, close all
save_figs = 0;

cd '../../figures/plots/mri/'
addpath('../../functions/')
run('figure_properties_aet.m')

rgb = [255 164 46; % value
    62 145 165  % background
    214 133 206]/255; % effort PE (unsigned)

%% ========================== if doing spheres

load '~/Dropbox/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1_fit_MAP/glm2_1_excl/contrast_estimates_6mm_sphere.mat';
    rgb_coords = [repmat(rgb(1,:), 4, 1);
        repmat(rgb(2,:), 5, 1);
        repmat(rgb(3,:), 1, 1)];

ROI_list = {
    'left RCZp'
    'left 11m'
    'bilateral insula'
    'right dACC'
    'right RCZp'
    'left FPm'
    'right 14m'
    'bilateral putamen'
    'left pgACC (32d)'
    'right 9m'
    };

    peak_MNI_list = [
    -5 -2 49;  % left RCZp - value
    -2 46 -20; % vmPFC - value
     0 0 0;    % bilateral insula - value
     5 17 49;  % dACC - value (preSMA)
     10 -7 42; % right RCZp - background
    -14 58 6;  % FPm - background
     5 34 -16; % vmPFC - background
     0 0 0;    % bilateral putamen - background
    -2 43 16;  % left pgACC - background
     7 58 25]; % right 9m - effort PE

%% ========================= Plot 
alpha = 0.05/3; % correct for number of test within each region 

mean_y = squeeze(mean(subject_sphere_data,1));
n = size(subject_sphere_data, 1);
sem_y = squeeze(std(subject_sphere_data, 0, 1)) / sqrt(n);

for i = 1:size(ROI_list, 1)
    figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.small_panel);
    h = bar([1:3], mean_y(i,:), 'FaceColor',rgb_coords(i,:), 'EdgeColor',rgb_coords(i,:)); hold on
    title(ROI_list{i})
    subtitle(['MNI: ' num2str(peak_MNI_list(i,:))]);

    ylabel('Contrast estimates')

    for m = 1:3
        % Generate jittered x-coordinates
        xJitter = (rand(n, 1) - 0.5) * 0.5;
        x = m + xJitter;

        % Plot the raw data points
        scatter(x, subject_sphere_data(:,i,m),30, h.FaceColor + (1-h.FaceColor) * 0.4, 'filled', 'MarkerEdgeAlpha', 0.5,'MarkerFaceAlpha', 0.5);
    end

    errorbar(mean_y(i,:), sem_y(i,:), 'k', 'LineStyle', 'none', 'CapSize',0, 'LineWidth',1.2)

    xticklabels({'Value', 'Avg. eff.', 'eff. PE'});
    xtickangle(45);

    % statistics
    [h, p, CI, t] = ttest(squeeze(subject_sphere_data(:,i,1)),squeeze(subject_sphere_data(:,i,2)), "Alpha",alpha);

    if p <= alpha
        sig_val = textbypos(0.42, 0.73,'*');
    else
        sig_val = textbypos(0.42, 0.73,'ns.');
    end

    fprintf('%s_val_background \n',ROI_list{i})
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)]), CI, h

    [h, p, CI, t] = ttest(squeeze(subject_sphere_data(:,i,1)), squeeze(subject_sphere_data(:,i,3)), "Alpha",alpha);

    if p <= alpha
        sig_val = textbypos(0.51, 0.82,'*');
    else
        sig_val = textbypos(0.51, 0.82,'ns.');
    end

    fprintf('%s_val_PE \n',ROI_list{i})
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)]), CI, h

    [h, p, CI, t] = ttest(squeeze(subject_sphere_data(:,i,2)), squeeze(subject_sphere_data(:,i,3)), "Alpha",alpha);

    if p <= alpha
        sig_val = textbypos(0.6, 0.73,'*');
    else
        sig_val = textbypos(0.6, 0.73,'ns.');
    end

    fprintf('%s_background_PE \n',ROI_list{i})
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)]), CI, h

    FormatFig_For_Export(gcf,11,fontname,widths.axis)
    if save_figs == 1
        print(['~/Dropbox/average-effort/code/figures/plots/mri/', sprintf('contrast_estimates_sphere6mm_%s', ROI_list{i})],'-dsvg')
    end
end
