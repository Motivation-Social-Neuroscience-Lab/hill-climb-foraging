function df = buildData(config, fit_flag, nsim)

arguments
    config struct % contains
    fit_flag logical % 1 if fitting, 0 if simulating
    nsim % only required if simulating
end

if fit_flag == 0 % if simulating
    % NOTE: we have to simulate by block, because we don't know how many trials the agent will go through (depending on choices)
    % so we need to give more trials than actually used.

    load([config.paths.dataDerived, 'behav_summary_', config.version]);
    results(config.excluded_subjects) = [];

    for iS = 1:length(results)

        % load the trials in each block
        for iB = 1:config.task.nBlocks
            df{iS}{iB}.response = NaN([100,1]); % set 100 trials maximum - agent won't exceed this per block

            switch config.version
                case 'online'
                    v = results{iS}.effortLevel(results{iS}.blockNumber == iB); v = repmat(v, ceil(100/numel(v)), 1);
                    df{iS}{iB}.cueEffort = v(1:100);

                    df{iS}{iB}.outcomeEffort = df{iS}{iB}.cueEffort; % deterministic cue

                case {'mri', 'v3'}
                    v = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.effortLevel(results{iS}.blockNumber == iB)); v = repmat(v, ceil(100/numel(v)), 1);
                    df{iS}{iB}.cueEffort = v(1:100);

                    df{iS}{iB}.outcomeEffort = df{iS}{iB}.cueEffort; % deterministic cue

                case 'v1'
                    v = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.effortLevel(results{iS}.blockNumber == iB)); v = repmat(v, ceil(100/numel(v)), 1);
                    df{iS}{iB}.cueEffort = v(1:100);

                    v = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.realEffort(results{iS}.blockNumber == iB)); v = repmat(v, ceil(100/numel(v)), 1);
                    df{iS}{iB}.outcomeEffort = v(1:100); % probabilistic cue
                    
            end

            v = results{iS}.blockType(results{iS}.blockNumber == iB); v = repmat(v, ceil(100/numel(v)), 1);
            df{iS}{iB}.blockType = v(1:100);

            v = results{iS}.reward(results{iS}.blockNumber == iB); v = repmat(v, ceil(100/numel(v)), 1);
            df{iS}{iB}.reward = v(1:100);

        end
    end

elseif fit_flag == 1 % if fitting data
    load([config.paths.data_behav, 'behav_summary_', config.version]);
    results(config.excluded_subjects) = [];

    for iS = 1:length(results)

        for iB = 1:config.task.nBlocks
            df{iS}{iB}.response = results{iS}.response(results{iS}.blockNumber == iB);
            
            switch config.version
                case 'online'
                    df{iS}{iB}.cueEffort = results{iS}.effortLevel(results{iS}.blockNumber == iB); % already converted effort level
                    df{iS}{iB}.outcomeEffort = results{iS}.effortLevel(results{iS}.blockNumber == iB); % already converted effort level

                case {'mri', 'v3'}
                    df{iS}{iB}.cueEffort = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.effortLevel(results{iS}.blockNumber == iB));
                    df{iS}{iB}.outcomeEffort = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.effortLevel(results{iS}.blockNumber == iB)); % deterministic cue

                case 'v1'
                    df{iS}{iB}.cueEffort = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.effortLevel(results{iS}.blockNumber == iB));
                    df{iS}{iB}.outcomeEffort = arrayfun(@(x) config.task.magnitudeToLevel(x), results{iS}.realEffort(results{iS}.blockNumber == iB)); % probabilistic cue
            end

            df{iS}{iB}.blockType = results{iS}.blockType(results{iS}.blockNumber == iB);
            df{iS}{iB}.reward = results{iS}.reward(results{iS}.blockNumber == iB);

        end
    end
end


