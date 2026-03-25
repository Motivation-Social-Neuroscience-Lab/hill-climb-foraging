%% Model comparison for AET Models
% This script compares models fit using the fitAET script, using metrics
% including BIC, AIC, psuedo-R2 and (protected) exceedance probabilities
%
% based on code from Todd Vogel 2024 for PAR task 
%
% Emma Scholey
% Date: 19/11/2025

%% Set up ------------------------------------------------------------------
clearvars; close all

addpath('./helperFunctions')

study_version = 'mri'; % which version of data to look at (v1, v3, mri)
fit_type = 'MAP';

model_ids = [1:3];
%model_ids = [1,2,3,6] % don't do 4 because beta goes weird
%model_ids = [1,3,5,6,14,16:19];
%model_ids = [1:6];
%model_ids = [7:12];
%model_ids = [1,2];
%% Load model outputs -----------------------------------------------------
fit_flag = 0;

config = config_study(study_version, fit_flag);

fitted_models = cell(1,length(model_ids));

% Generate model IDs from 101 to 121
model_ids = arrayfun(@(x) sprintf('M%d', x), model_ids, 'UniformOutput', false);

for imodel = 1:length(model_ids)

    switch fit_type
        case 'MAP'
            load([config.paths.data_fit, 'fitting_hierarchical_' model_ids{imodel}]);
        case 'MLE'
            load([config.paths.data_fit, 'fitting_MLE_' model_ids{imodel}]);
    end

    fitted_models{imodel} = modout;
    
end
fitted_models = cell2struct(fitted_models, model_ids, 2);

%% Compare models ------------------------------------------------------------------
fits_table = EMmc_ms(fitted_models, model_ids, config, fit_type); % function to plot comparisons based on log model evidence, BIC, and exceedance probabilities

