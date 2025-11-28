
clear all
close all

model_dir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed/sub-';

subj = [1:4, 6:10, 12:31, 33:41]; % The file (subject) numbers of the files to be used in the analysis
gen_figs = 1;

subj = 1

% figure, histogram(modelEstimates.z_backgroundEffort, 6); title('Background effort')
% figure, histogram(modelEstimates.z_effortPE, 6); title('Effort PE')
% figure, histogram(modelEstimates.z_value, 6); title('Value')

num_subj = length(subj);

group_corrs = size(num_subj, 6);

for iS = 1:num_subj
    id = num2str(subj(iS), '%02d');

    modelEstimates = readtable([model_dir, id, '/model_estimates_M1.csv']);

    V = modelEstimates.predictedValue;
    E = modelEstimates.effortLevel;
    PE = modelEstimates.effortPE;
    B = modelEstimates.backgroundEffort;
    effort = modelEstimates.effortLevel;
    env = modelEstimates.blockType;
    block = modelEstimates.blockNumber;

    %% CONDITION-WISE (6x6) RDMs for Effort(1..3) x Environment(1..2)
    % Required trial-level inputs in workspace (column vectors, same length):
    %   effort   : effort level per trial (integer in {1,2,3})
    %   env      : environment per trial (integer in {1,2})
    %   V        : model-predicted value per trial (scalar)
    %   PE       : effort prediction error per trial (scalar; signed or unsigned)
    %   B    : background/average effort per trial (scalar)
    %
    % Output: 6x6 RDMs (condition-wise) and heatmaps for:
    %   RDM_V, RDM_PE, RDM_muEff
    %
    % Condition order (rows/cols): [E=1×Env=1..2, E=2×Env=1..2, E=3×Env=1..2]

    env(env==11) = 1; env(env==99) = 2;
    assert(all(ismember(unique(effort), [1 2 3])),'effort must be in {1,2,3}');
    assert(all(ismember(unique(env),    [1 2]  )),'env must be in {1,2}');

    %% ---------------- Condition index: Effort x Env -> 6 levels ----------------
    % Canonical order: [ (Eff=1,Env=1) (Eff=1,Env=2) (Eff=2,Env=1) (Eff=2,Env=2) (Eff=3,Env=1) (Eff=3,Env=2) ]
    eff_levels = 1:3;
    env_levels = 1:2;
    [effGrid, envGrid] = ndgrid(eff_levels, env_levels);   % 3x2
    cond_pairs = [effGrid(:) envGrid(:)];                  % 6x2 in canonical order

    % Map each trial to a condition id 1..6 using the canonical order above
    cond_id = nan(size(effort));
    for c = 1:size(cond_pairs,1)
        hit = (effort==cond_pairs(c,1)) & (env==cond_pairs(c,2));
        cond_id(hit) = c;
    end

    %% -------- Effort(1..3) × Env(1..2) × Block(1..nBlocks) counts --------
    % Assumes:
    %   effort in {1,2,3}
    %   env    in {1,2}   (you already recoded 11->1, 99->2)
    %   block  is the run/block number (any integers)

    % Map blocks to 1..nBlocks
    uBlocks = unique(block(~isnan(block)));
    [~, ~, block_id] = unique(block);      % maps arbitrary block labels to 1..nBlocks
    nBlocks = numel(uBlocks);

    % Valid trials
    valid = ~isnan(effort) & ~isnan(env) & ~isnan(block_id);

    % 3×2×nBlocks tensor: Effort × Env × Block
    counts_eff_env_by_block = accumarray( ...
        [effort(valid), env(valid), block_id(valid)], 1, ...
        [3, 2, nBlocks], @sum, 0);

    % Also handy aggregates
    counts_eff_env_overall = sum(counts_eff_env_by_block, 3);    % 3×2 (summed across blocks)


    %group_counts(iS) = counts;
    % Condition labels for plotting
    cond_labels = arrayfun(@(e,ev) sprintf('E%d-Env%d', e, ev), cond_pairs(:,1), cond_pairs(:,2), 'UniformOutput', false);

    %% ---------------- Condition means ----------------
    grpmean = @(x,g) splitapply(@mean, x, findgroups(g));    % mean per condition id

    V_means     = grpmean(V,     cond_id);     % 6x1
    E_means     = grpmean(E,     cond_id);     % 6x1
    PE_means    = grpmean(PE,    cond_id);     % 6x1
    muEff_means = grpmean(B, cond_id);     % 6x1


    X = [E_means(:) muEff_means(:)];
    Xz = zscore(X,0,1); % make E and muEff on same scale to be comparable

    RDM_V     = pdist2(V_means, V_means, 'euclidean');         % 6x6
    RDM_E     = pdist2(E_means, E_means, 'euclidean');         % 6x6
    RDM_PE    = pdist2(PE_means, PE_means, 'euclidean');        % 6x6
    RDM_muEff = pdist2(muEff_means, muEff_means, 'euclidean');     % 6x6

    RDM_add = pdist2(Xz, Xz, 'cityblock');
    RDM_int = pdist2(Xz, Xz, 'euclidean');

    %% ---------------- Plot heatmaps ----------------

    if gen_figs == 1
        figure('Color','w','Position',[120 120 1050 380]);
        tiledlayout(1,4,'TileSpacing','compact','Padding','compact');

        % Value
        nexttile; imagesc(RDM_V); axis square; colorbar;
        title('Model Value RDM  |mean(V)_i - mean(V)_j|');
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);

        % Effort
        nexttile; imagesc(RDM_E); axis square; colorbar;
        title('Effort RDM  |mean(E)_i - mean(E)_j|');
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);

        % Effort PE
        nexttile; imagesc(RDM_PE); axis square; colorbar;
        title('Effort PE RDM  |mean(PE)_i - mean(PE)_j|');
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);

        % Background Effort
        nexttile; imagesc(RDM_muEff); axis square; colorbar;
        title('Background Effort RDM  |mean(\mu_{eff})_i - mean(\mu_{eff})_j|');
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);

        sgtitle('Condition-wise (6×6) Model RDMs: Effort(1–3) × Environment(1–2)','FontWeight','bold');

        figure('Color','w','Position',[120 120 1050 380]);
        tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

        % Additive
        nexttile; imagesc(RDM_add); axis square; colorbar;
        title('Additive RDM ');
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);

        % Integrated
        nexttile; imagesc(RDM_int); axis square; colorbar;
        title('Integrated RDM' );
        set(gca,'YDir','normal','XTick',1:6,'YTick',1:6,'XTickLabel',cond_labels,'YTickLabel',cond_labels); xtickangle(45);
    end

    %% ---------------- Optional: export variables for RSA ----------------
    % Vectorised upper triangles (excluding diagonal), z-score recommended before regression RSA
    UT = triu(true(6),1);
    vec_RDM_V     = RDM_V(UT);
    vec_RDM_E     = RDM_E(UT);
    vec_RDM_PE    = RDM_PE(UT);
    vec_RDM_muEff = RDM_muEff(UT);

    % Display correlations between model RDMs (are they uniquely identifiable)
    RDM_corrs_val_pe = correlateRDMs(RDM_PE, RDM_V);
    RDM_corrs_val_bE = correlateRDMs(RDM_muEff, RDM_V);
    RDM_corrs_E_bE = correlateRDMs(RDM_muEff, RDM_E);
    RDM_corrs_E_pe = correlateRDMs(RDM_PE, RDM_E);
    RDM_corrs_pe_bE = correlateRDMs(RDM_muEff, RDM_PE);
    RDM_corrs_val_E = correlateRDMs(RDM_V, RDM_E);

    RDM_corrs_int_E = correlateRDMs(RDM_int, RDM_E);
    RDM_corrs_add_E = correlateRDMs(RDM_add, RDM_E);
    RDM_corrs_int_bE = correlateRDMs(RDM_int, RDM_muEff);
    RDM_corrs_add_bE = correlateRDMs(RDM_add, RDM_muEff);

    % Spearman's rank: 0.80.
    display(['Value x PE:   ' num2str(RDM_corrs_val_pe.spearman_r)])
    display(['Value x Background:   ' num2str(RDM_corrs_val_bE.spearman_r)])
    display(['Effort x Background:   ' num2str(RDM_corrs_E_bE.spearman_r)])
    display(['Effort x PE:   ' num2str(RDM_corrs_E_pe.spearman_r)])
    display(['Background x PE:   ' num2str(RDM_corrs_pe_bE.spearman_r)])
    display(['Value x Effort:   ' num2str(RDM_corrs_val_E.spearman_r)])

    display(['Integrated x Effort:   ' num2str(RDM_corrs_int_E.spearman_r)])
    display(['Additive x Effort:   ' num2str(RDM_corrs_add_E.spearman_r)])
    display(['Integrated x Background:   ' num2str(RDM_corrs_int_bE.spearman_r)])
    display(['Additive x Background:   ' num2str(RDM_corrs_add_bE.spearman_r)])


    % log for each subject

    group_corrs(iS,1) = RDM_corrs_E_bE.spearman_r;
    group_corrs(iS,2) = RDM_corrs_E_pe.spearman_r;
    group_corrs(iS,3) = RDM_corrs_int_E.spearman_r;
    group_corrs(iS,4) = RDM_corrs_int_bE.spearman_r;
    group_corrs(iS,5) = RDM_corrs_add_E.spearman_r;
    group_corrs(iS,6) = RDM_corrs_add_bE.spearman_r;

end

figure, boxplot(group_corrs)
ylim([-0.4, 1])
set(gca, 'XTickLabel', {'E x B', 'E x PE', 'Int x E', 'Int x B', 'Add x E', 'Add x B'})
%% ----------------------- Helper functions

% Inputs:
%   A, B   : two square RDMs of the same size (n x n)
% Optional:
%   block  : trial block IDs (n x 1). If provided and you want cross-block only, set useCrossBlock=true.

function stats = correlateRDMs(A, B)
n = size(A,1);
UT = triu(true(n),1);                % upper-tri without diagonal
a = A(UT);  b = B(UT);

% Rank correlations (robust to scale; Kendall is tie-aware)
[rho_s, p_s] = corr(a, b, 'type','Spearman','rows','pairwise');
[rho_k, p_k] = corr(a, b, 'type','Kendall','rows','pairwise'); % tau-b

stats = struct('spearman_r',rho_s,'spearman_p',p_s, ...
    'kendall_tau',rho_k,'kendall_p',p_k, ...
    'n_pairs',numel(a));
end