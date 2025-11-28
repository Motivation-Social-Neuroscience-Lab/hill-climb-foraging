
# AET: Reported statistics for AET behaviour tasks
# created 03/02/25 E. Scholey for average effort task
# SETUP ################ 
rm(list = ls(all = TRUE)) # clear environment

# load packages
library(tidyverse)
library(MASS)
library(lme4)
library(glmmTMB)
library(sjPlot)

setwd('~/Dropbox/average-effort/code/analysis/') # adjust as required

# select the data you want to analyse

task_version = 'v3' # v1, v3 or mri. 
model_number = '' #If running statistics on simulated data, include model_number + underscore. If not, then leave blank ('')

# load and identify best model 
# for all models, best random effects structure is:
# (1 + effortContrasts2_1 + effortContrasts3_2|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + blockContrasts_low + blockContrasts_mid + blockContrasts_high + further covariates||subjectNumber)
# this is according to AIC. Somtimes, AIC for a model with no intercept for second part of random effects structure (0+) has lower AIC, however this is negligible (diff AIC < 2).
# Thus stick with the more complex random effects structure (checked if results in different p-value conclusions, and the conclusions are identical)

load(file = paste0('glmm_output/glm_model_comparison_main_', model_number, task_version, '.RData'))
main_model <- results[[3]]

load(file = paste0('glmm_output/glm_model_comparison_main_reward_', model_number, task_version, '.RData'))
reward_model <- results[[6]]

load(file = paste0('glmm_output/glm_model_comparison_effHistory_', model_number, task_version, '.RData'))
eff_hist_model <- results[[5]]

load(file = paste0('glmm_output/glm_model_comparison_exertEffHistory_', model_number, task_version, '.RData'))
exert_eff_hist_model <- results[[5]]


anova(main_model)
car::Anova(main_model)

# output table of odds ratios and p-values
tab_model(main_model)
z_scores <- data.frame(round(summary(main_model)$coefficients$cond[, 'z value'],2))

tab_model(reward_model)
z_scores <- data.frame(round(summary(reward_model)$coefficients$cond[, 'z value'],2))

tab_model(eff_hist_model)
z_scores <- data.frame(round(summary(eff_hist_model)$coefficients$cond[, 'z value'],2))

tab_model(exert_eff_hist_model)
z_scores <- data.frame(round(summary(exert_eff_hist_model)$coefficients$cond[, 'z value'],2))

# Compare larger vs smaller model to get (null) Bayes factor for previous expected value
# Using BIC equation (Wagenmakers, 2007): BF01 = exp((BIClarger - BICsmaller) / 2)
reward_BF_01 <- exp((BIC(reward_model) - BIC(main_model)) / 2)

eff_hist_BF_01 <- exp((BIC(eff_hist_model) - BIC(main_model)) / 2)

exert_eff_hist_BF_01 <- exp((BIC(exert_eff_hist_model) - BIC(main_model)) / 2)


