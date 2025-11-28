function [agentParams] = buildParams(model,funcOptions)

allParamNames = {'kOffer','k', 'beta_one', 'beta_two', 'alpha'};

switch funcOptions.type
    case 'simulate_new'

        % convert parameters to table to index by name
        params = array2table(repmat(funcOptions.params,[funcOptions.nSim,1]));
        params.Properties.VariableNames = allParamNames;

        switch model.numK
            case 'one'
                agentParams.params.kOffer = params.kOffer;
            case 'two'
                agentParams.params.kOffer = params.kOffer;
                agentParams.params.k = params.k; % allow separate k's
        end

        switch model.discountFunction
            case {'effort', 'effort_adaptive','effort_opp_cost', 'reward', 'exert_opp_cost', 'effort_test'}
                agentParams.params.alpha = params.alpha;
        end
        
        switch model.numBeta
            case 'one'
                agentParams.params.beta_one = params.beta_one;
            case 'two'
                agentParams.params.beta_one = params.beta_one;
                agentParams.params.beta_two = params.beta_two; % allow separate k's
        end

        agentParams.params = struct2table(agentParams.params);
        agentParams.names = agentParams.params.Properties.VariableNames;

    case 'simulate_fit'

        load(sprintf('../../data_derived/%s/fitting/fitting_M%d', funcOptions.version, model.modelNumber), 'minNLLFitParams');
        agentParams.params = minNLLFitParams;
        agentParams.names = agentParams.params.Properties.VariableNames;

    case 'fit'
        % generate set of parameters to start fmincon search, or generate
        % set of fake parameters for parameter recovery

        % set lower and upper bounds for fmincon search
        % {'kOffer','k', 'beta_one', 'beta_two', 'alpha'}
        lb = array2table([0,-3,0,0,0]); lb.Properties.VariableNames = allParamNames;
        ub = array2table([3, 3,50,50,1]); ub.Properties.VariableNames = allParamNames;

        switch model.numK
            case 'one'
                agentParams.params.kOffer = ub.kOffer*rand(funcOptions.nSim,1);
            case 'two'
                agentParams.params.kOffer = ub.kOffer*rand(funcOptions.nSim,1);
                agentParams.params.k = ub.k*rand(funcOptions.nSim,1); % allow separate k's
        end

        switch model.numBeta
            case 'one'
                agentParams.params.beta_one = exprnd(2,[funcOptions.nSim,1]);
            case 'two'
                agentParams.params.beta_one = exprnd(2,[funcOptions.nSim,1]);
                agentParams.params.beta_two = exprnd(2,[funcOptions.nSim,1]);
        end

        switch model.discountFunction
            case {'effort', 'effort_adaptive','effort_opp_cost', 'reward', 'exert_opp_cost', 'effort_test'}
                agentParams.params.alpha = ub.alpha*rand(funcOptions.nSim,1);
        end

        agentParams.params = struct2table(agentParams.params);
        agentParams.names = agentParams.params.Properties.VariableNames;

        agentParams.lb = table2array(lb(:,agentParams.names)); % only get the bounds we need for this model
        agentParams.ub = table2array(ub(:,agentParams.names));
        agentParams.nParams = numel(agentParams.names);

    case 'recover'

        % load real participant data to fit pdf and generate simulated parameters
        load(sprintf('../../data_derived/%s/fitting/fitting_M%d', funcOptions.version, model.modelNumber), 'minNLLFitParams');

        switch model.numK
            case 'one'
                agentParams.params.kOffer = rand(funcOptions.nSim,1)*(mean(minNLLFitParams.kOffer) + 3*std(minNLLFitParams.kOffer));
            case 'two'
                agentParams.params.kOffer = rand(funcOptions.nSim,1)*(mean(minNLLFitParams.kOffer) + 3*std(minNLLFitParams.kOffer));
                agentParams.params.k = rand(funcOptions.nSim,1)*(mean(minNLLFitParams.k) + 3*std(minNLLFitParams.k));
        end

        switch model.numBeta
            case 'one'
                agentParams.params.beta_one = exprnd(2,[funcOptions.nSim,1]);
            case 'two'
                agentParams.params.beta_one = exprnd(2,[funcOptions.nSim,1]);
                agentParams.params.beta_two = exprnd(2,[funcOptions.nSim,1]);
        end

        switch model.discountFunction
            case {'effort', 'effort_adaptive','effort_opp_cost', 'reward', 'exert_opp_cost', 'effort_test'}
                agentParams.params.alpha = rand(funcOptions.nSim,1)*(mean(minNLLFitParams.alpha) + 3*std(minNLLFitParams.alpha));
        end

        agentParams.params = struct2table(agentParams.params);
        agentParams.names = agentParams.params.Properties.VariableNames;
        agentParams.nParams = numel(agentParams.names);


end
