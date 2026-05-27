%% Set up ------------------------------------------------------------------
clearvars; close all

addpath('../modelling/helperFunctions')
addpath(genpath('./'))
run figure_properties_aet.m

study = {'v1', 'v3', 'mri'};
win_model =[1,2,1];
model_ids = {'LearnEnv', 'ActHist', 'FixEnv'};

%%
for s = 1:numel(study)

    study_version = study{s};
    config = config_study(study_version, 0);

    %% Plot BIC INT for publication
    load([config.paths.data_fit, 'fits_table.mat']);
    figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);

    nexttile;
    bar(fits_table.bic - min(fits_table.bic), 'FaceColor',colour.model);
    set(gca, 'XTick', 1:numel(model_ids), 'XTickLabel', model_ids, 'XTickLabelRotation', 45);
    ylabel('Δ BICint from lowest');

    FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
    %print([export_path, sprintf('%s/fig_%s_BIC', study_version, study_version)],'-dsvg')

    %% Plot model identifiability
    load([config.paths.data_fit, 'MI_', study_version]);
    n_models = length(fitted_sim_models);
    nsims = fitted_sim_models{1,1}.nsubj;

    bic_mat = zeros(n_models, n_models);
    xp_mat = zeros(n_models, n_models);
    for irow = 1:height(fitted_sim_models)
        lme_mat = zeros(nsims,n_models);

        for jcol = 1:width(fitted_sim_models)
            bic_mat(irow,jcol) = fitted_sim_models{irow, jcol}.bicint;
            lme_mat(:,jcol) = fitted_sim_models{irow, jcol}.lme;
        end
        [~, ~, xp_mat(irow, :)] = spm_BMS(lme_mat);
    end

    figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);
    h = heatmap(xp_mat,'MissingDataColor','w', 'GridVisible', 'off', 'ColorLimits',[0,1], 'CellLabelColor', 'none');
    ylabel('simulated')
    xlabel('recovered')
    h.XDisplayLabels = model_ids;
    h.YDisplayLabels = model_ids;
    colormap(brewermap([], 'Blues'));
    h.FontSize = 14;

    FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
    %print([export_path, sprintf('%s/fig_%s_MI', study_version, study_version)],'-dsvg')

    %% Plot parameter recovery

    load([config.paths.data_fit, 'PR_', study_version, '_M', num2str(win_model(s))]);

    figure('Units', 'centimeters', 'PaperPositionMode', 'auto' ,'Position',figsize.square);
    corr_coeffs = corr(sim_real_t.', sim_fitted_t.', 'Type', 'Spearman');
    corr_coeffs = round(corr_coeffs, 2);

    h = heatmap(corr_coeffs,'MissingDataColor','w', 'GridVisible', 'off', 'ColorLimits',[-1,1]);
    colormap(brewermap([], 'RdBu'));

    h.XDisplayLabels = {'\kappa', '\beta', '\alpha'};
    h.YDisplayLabels = {'\kappa', '\beta', '\alpha'};
    h.XLabel = 'simulated';
    h.YLabel = 'recovered';

    h.FontSize = 14;

    FormatFig_For_Export(gcf,fontsize,fontname,widths.axis)
    %print([export_path, sprintf('%s/fig_%s_PR', study_version, study_version)],'-dsvg')

end