%%% Plot contrast estimates for voxels of interest
%%% created 16 June 2025 Emma Scholey for AET analysis

clear, close all
save_figs = 0;

cd '../../../../figures/'
run functions/figure_properties_aet.m

rgb = [0 128 0; % value
    170 0 0  % background
    0 0 128]/255; % effort PE (unsigned)

rgb_coords = [repmat(rgb(1,:), 7, 1);repmat(rgb(2,:), 4, 1);repmat(rgb(3,:), 2, 1)];

% Define MNI coordinates (rows = different peaks)
mni_coords = [
    % value pos peaks
    -5, -2, 49;
    36, 41, -6;
    -38, 31, -11;
    -19, 48, 1;
    % value neg peaks
    2, 17, 47;
    34, 22, 6;
    -36, 22, -4;
    % background peaks
    7, -17, 49;
    7, 29, -11;
    -7, 29, 18;
    -2, 48, -8;
    % effort PE peaks
    7, 58, 25;
    5, 29, -16;

    ];

labels = {'left_RCZp'
    'right_47o'
    'left_47o'
    'left_32pl_11m'
    'right_8m'
    'right_insula'
    'left_insula'
    'right_RCZp'
    'right_14m'
    'left_24'
    'left_11m'
    'right_9m'
    'right_14m'};

load '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/second_level/z_6m_csf_wm_compcor_M1/glm2/contrast_estimates_peak_voxels.mat'

mean_y = squeeze(mean(Y,1));
n = size(Y, 1);
sem_y = squeeze(std(Y, 0, 1)) / sqrt(n);

for i = 1:size(mni_coords, 1)
    figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.small_panel);
    h = bar([1:3], mean_y(i,:), 'FaceColor',rgb_coords(i,:), 'EdgeColor',rgb_coords(i,:)); hold on
    title(sprintf('MNI: [%d %d %d]', mni_coords(i,1), mni_coords(i,2), mni_coords(i,3)));

    ylabel('Contrast estimates')

    s = scatter([1:3],squeeze(Y(:,i,:)),40, h.FaceColor + (1-h.FaceColor) * 0.4, 'filled', 'MarkerEdgeAlpha', 0.5,'MarkerFaceAlpha', 0.5, 'LineWidth',1,'jitter','on', 'jitterAmount',0.05);
    errorbar(mean_y(i,:), sem_y(i,:), 'k', 'LineStyle', 'none', 'CapSize',0, 'LineWidth',1.2)

    xticklabels({'Value', 'Backgr. eff.', 'eff. PE (abs)'});
    xtickangle(45);

    yl = ylim;           % Get current y-axis limits
    ylim([yl(1), yl(2) + 0.2]);

    % statistics
    [~, p, ~, t] = ttest(squeeze(Y(:,i,1)),squeeze(Y(:,i,2)));

    if p < .001
        sig_val = textbypos(0.42, 0.8,'**');
    elseif p >= .001 && p <= .05
        sig_val = textbypos(0.42, 0.8,'*');
    else
        sig_val = textbypos(0.42, 0.8,'ns.');
    end


    fprintf('%s_%d_%d_%d_val_background \n',labels{i}, mni_coords(i,1), mni_coords(i,2), mni_coords(i,3))
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)])

    [~, p, ~, t] = ttest(squeeze(Y(:,i,1)), squeeze(Y(:,i,3)));

    if p < .001
        sig_val = textbypos(0.5, 0.9,'**');
    elseif p >= .001 && p <= .05
        sig_val = textbypos(0.5, 0.9,'*');
    else
        sig_val = textbypos(0.5, 0.9,'ns.');
    end

    fprintf('%s_%d_%d_%d_val_PE \n',labels{i}, mni_coords(i,1), mni_coords(i,2), mni_coords(i,3))
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)])
    [~, p, ~, t] = ttest(squeeze(Y(:,i,2)), squeeze(Y(:,i,3)));

    if p < .001
        sig_val = textbypos(0.58, 0.8,'**');
    elseif p >= .001 && p <= .05
        sig_val = textbypos(0.58, 0.8,'*');
    else
        sig_val = textbypos(0.58, 0.8,'ns.');
    end

    fprintf('%s_%d_%d_%d_background_PE \n',labels{i}, mni_coords(i,1), mni_coords(i,2), mni_coords(i,3))
    disp(['t = ' num2str(t.tstat)]), disp(['p = ' num2str(p)])

    FormatFig_For_Export(gcf,12,fontname,widths.axis)
    if save_figs == 1
        print([export_path, sprintf('contrast_estimates_%d_%d_%d_%s',mni_coords(i,1), mni_coords(i,2), mni_coords(i,3), labels{i})],'-dsvg')
    end
end
