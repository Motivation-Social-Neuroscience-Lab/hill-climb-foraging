function spec = getModelSpec(model, cfg)
% GETMODELSPEC Build a parameter specification struct for an AET model.
%
% spec = GETMODELSPEC(model, cfg) inspects the model metadata (typically a
% row from `AETModelTable_new.xlsx` converted via table2struct) and returns
% a struct that centralises all parameter bookkeeping for that model:
%   - parameter order and names
%   - lower/upper bounds
%   - default simulation values
%   - flags describing which components are active
%
% Inputs
%   model : struct containing columns from the model table (must include
%           fields such as `modelNumber`, `numK`, `numBeta`,
%           `discountFunction`, etc.)
%   cfg   : (optional) configuration struct produced by loadConfig. When
%           supplied, its parameter bounds and default simulation values
%           override the generic defaults defined below.
%
% Output
%   spec  : struct with fields
%             .modelNumber
%             .name
%             .paramNames
%             .nParams
%             .bounds.lb
%             .bounds.ub
%             .defaults.simulation
%             .components (logical flags for key features)
%
% Example
%   cfg = loadConfig('mri');
%   model = table2struct(modelTable(modelTable.modelNumber == 107,:));
%   spec = getModelSpec(model, cfg);
%
% Author: Emma Scholey
% Date  : 20 Nov 2025

arguments
    model struct
    cfg struct = struct()
end

% -------------------------------------------------------------------------
% Base parameter universe (extend here if new parameters are added)
% -------------------------------------------------------------------------
allParamNames = {'kOffer','k','beta_one','beta_two','alpha','weight','bias'};
defaultLB     = [0,        0,  0,          0,          0,      0,        -5];
defaultUB     = [1,        1, 50,         50,          1,      1,         5];
defaultSim    = [0.5,   0.25,  2,          2,        0.2,    0.5,        0];

% If config provides overrides, use them (assume same ordering as above)
if isfield(cfg, 'fitting') && isfield(cfg.fitting, 'paramBounds')
    cfgLB = cfg.fitting.paramBounds.lower;
    cfgUB = cfg.fitting.paramBounds.upper;
    if numel(cfgLB) >= numel(defaultLB)
        defaultLB(1:numel(cfgLB)) = cfgLB;
    end
    if numel(cfgUB) >= numel(defaultUB)
        defaultUB(1:numel(cfgUB)) = cfgUB;
    end
end

if isfield(cfg, 'simulation') && isfield(cfg.simulation, 'defaultParams')
    cfgDefaults = cfg.simulation.defaultParams;
    if numel(cfgDefaults) >= numel(defaultSim)
        defaultSim(1:numel(cfgDefaults)) = cfgDefaults;
    end
end

lbMap = containers.Map(allParamNames, num2cell(defaultLB));
ubMap = containers.Map(allParamNames, num2cell(defaultUB));
simMap = containers.Map(allParamNames, num2cell(defaultSim));

% -------------------------------------------------------------------------
% Determine active parameters for this model
% -------------------------------------------------------------------------
paramList = {};
componentFlags = struct( ...
    'hasDualK', false, ...
    'hasDualBeta', false, ...
    'usesWeight', false, ...
    'usesBias', false);

% kOffer is always present
paramList{end+1} = 'kOffer';

% Secondary k?
if isfield(model, 'numK') && strcmp(model.numK, 'two')
    componentFlags.hasDualK = true;
    paramList{end+1} = 'k';
end

% Beta parameters
if isfield(model, 'numBeta')
    switch model.numBeta
        case 'one'
            paramList{end+1} = 'beta_one';
        case 'two'
            componentFlags.hasDualBeta = true;
            paramList = [paramList, {'beta_one','beta_two'}];
    end
else
    % Default to single beta if the table does not specify
    paramList{end+1} = 'beta_one';
end

% Learning rate alpha (always used in current model family)
paramList{end+1} = 'alpha';

% Discount-function-specific parameters
if isfield(model, 'discountFunction') && ...
        ismember(model.discountFunction, {'weight','weight_k'})
    componentFlags.usesWeight = true;
    paramList{end+1} = 'weight';
end

% Optional bias parameter (future-proofing)
if isfield(model, 'includeBias') && model.includeBias
    componentFlags.usesBias = true;
    paramList{end+1} = 'bias';
end

% Remove potential duplicates while preserving order
[~, uniqueIdx] = unique(paramList, 'stable');
paramList = paramList(sort(uniqueIdx));

% -------------------------------------------------------------------------
% Assemble specification struct
% -------------------------------------------------------------------------
spec = struct();
spec.modelNumber = model.modelNumber;
if isfield(model, 'modelName')
    spec.name = model.modelName;
else
    spec.name = sprintf('Model_%d', model.modelNumber);
end

spec.paramNames = paramList;
spec.nParams = numel(paramList);

spec.bounds.lb = arrayfun(@(p) lbMap(p{1}), paramList);
spec.bounds.ub = arrayfun(@(p) ubMap(p{1}), paramList);

% Provide defaults for simulations/start points
spec.defaults.simulation = arrayfun(@(p) simMap(p{1}), paramList);
spec.defaults.start = mean([spec.bounds.lb; spec.bounds.ub], 1);

spec.components = componentFlags;

% Convenience lookups
spec.indexMap = containers.Map(paramList, num2cell(1:spec.nParams));

end







