
%% Plot backgroundEffort over trials for two CSVs (one tile per subject)

% If you're not running this from the preprocessed folder, set baseDir:
baseDir = '/Volumes/appsmaj-effort-prey-fmri-scholey/aet_fMRI/preprocessed';

subs = [1:4, 6:10, 12:31, 33:41];

fileA = 'model_estimates_M2_fit_MAP.csv';
fileB = 'model_estimates_M1_fit_MAP.csv';

nSub  = numel(subs);
nCols = ceil(sqrt(nSub));
nRows = ceil(nSub / nCols);

figure('Color','w');
tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

for i = 1:nSub
    s = subs(i);
    subName = sprintf('sub-%02d', s);
    
    T1 = readtable(fullfile(baseDir, subName, fileA));
    T2 = readtable(fullfile(baseDir, subName, fileB));
    
    nexttile;
    hold on;
    
    plot(T1.trialN, zscore(T1.backgroundEffort), 'LineWidth', 1.2);
    plot(T2.trialN, zscore(T2.backgroundEffort), 'LineWidth', 1.2);
 
    title(subName, 'Interpreter','none');
    xlabel('trialN');
    ylabel('backgroundEffort');
    grid on;
    
    hold off;
end

legend({fileA, fileB}, 'Interpreter','none', 'Location','southoutside');