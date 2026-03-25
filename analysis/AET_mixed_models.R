# AET: plots and mixed models for all task versions
# created 21/02/23 E. Scholey for average effort task

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

task_version = 'mri' # v1, v3 or mri. 
model_number = '' #If running statistics on simulated data, include model_number + underscore. If not, then leave blank ('')

#read data
behav <- read.csv(paste('../data/behavioural/',task_version,'/behav_summary_',model_number, task_version,'.csv', sep = ""))

# exclude subject 32 for mri (didn't complete the task, too much movement)
if (model_number== ''){ # if running statistics on real subject data
  if (task_version == 'mri'){
    behav <- filter(behav,subjectNumber != 32)
  } else if (task_version == 'v1'){
    behav <- filter(behav,subjectNumber != 6)  
  } else if (task_version == 'v3'){
    behav <- filter(behav,subjectNumber > 16)  
  }
}

#------------------------- clean data -------------------------- <- <- #

if (model_number== ''){ # if running statistics on real subject data
  # Exclude those who accepted everything
  behav.subject_acceptAll_exclude <- behav %>% group_by(subjectNumber) %>% filter(response != 8888) %>% summarise(M = mean(response)) %>% filter(M > 0.95)
  behav <- filter(behav, !(subjectNumber %in% behav.subject_acceptAll_exclude$subjectNumber))
  
  # look at trials where they accepted but didn't reach the threshold
  failed_accepted <- behav %>% mutate(failed = timeInWindow < 1 & response == 1) %>% group_by(subjectNumber) %>% summarise(failed = mean(failed))
  excludeFailed <- failed_accepted %>% filter(failed > 0.2) # failed more than 20% of responses
  behav <- filter(behav, !(subjectNumber %in% excludeFailed$subjectNumber))
  
  # Exclude those who missed > 10% of trials
  missed_many <- behav %>% group_by(subjectNumber) %>% summarise(missed = mean(response == 8888))
  excludeMissed <- missed_many %>% filter(missed > 0.1) 
  behav <- filter(behav, !(subjectNumber %in% excludeMissed$subjectNumber))
  
  # remove missed trials
  behav <- behav %>% filter(response != 8888)
}

nSubj <- length(unique(behav$subjectNumber))

##--------------------------- prepare/recode data for mixed models ----------------------- 

total_avg_effort <- behav %>% mutate(effort = effort/111) %>% 
  group_by(blockType) %>% summarise(avg_effort = mean(effort)) 

# make factors of categorical predictors
behav$effortLevel <- factor(behav$effortLevel, labels = c("low", "mid", "high"), ordered = T)  
behav$blockType <- factor(behav$blockType, labels = c("easy", "hard"))

behav$effortHistory_numeric <- behav$effortHistory
behav$effortHistory <- factor(behav$effortHistory, labels = c("low", "mid", "high"), ordered = T)  
behav$exertedEffortHistory <- factor(behav$exertedEffortHistory, labels = c("wait", "low", "mid", "high"), ordered = T)  

behav$responseHistory <- factor(behav$responseHistory, labels = c('wait', 'accept'), ordered = T)

contrasts(behav$effortLevel) <- contr.sdif(3) # repeated contrasts ('sliding differences')
contrasts(behav$effortHistory) <- contr.sdif(3) # repeated contrasts ('sliding differences')
contrasts(behav$exertedEffortHistory) <- contr.sdif(4) # repeated contrasts (compare to reference ('wait'))
contrasts(behav$blockType) <- contr.sdif(2) # same as coding block type as 0.5 or -0.5 
contrasts(behav$responseHistory) <- contr.sdif(2) # same as coding block type as 0.5 or -0.5 

# scale continuous variables - z-standardise and centre, within subject
for (i in unique(behav$subjectNumber)){
  behav$trialNinBlock_scaled[behav$subjectNumber==i] <- scale(behav$trialNinBlock[behav$subjectNumber==i])
  behav$blockN_scaled[behav$subjectNumber==i] <- scale(behav$blockNumber[behav$subjectNumber==i])
}

if (model_number== ''){ # if running statistics on real subject data (we don't have reward variables for model simulated data)
  for (i in unique(behav$subjectNumber)){
    behav$rewardHistory_scaled[behav$subjectNumber==i] <- scale(behav$rewardHistory[behav$subjectNumber==i])
    behav$averageRewardRate_scaled[behav$subjectNumber==i] <- scale(behav$averageRewardRate[behav$subjectNumber==i])
    behav$averageEffortRate_1_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_1[behav$subjectNumber==i])
    behav$averageEffortRate_2_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_2[behav$subjectNumber==i])
    behav$averageEffortRate_3_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_3[behav$subjectNumber==i])
    behav$averageEffortRate_4_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_4[behav$subjectNumber==i])
    behav$averageEffortRate_5_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_5[behav$subjectNumber==i])
    behav$averageEffortRate_6_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_6[behav$subjectNumber==i])
    behav$averageEffortRate_7_scaled[behav$subjectNumber==i] <- scale(behav$averageEffortRate_7[behav$subjectNumber==i])
    behav$averageExertedRate_scaled[behav$subjectNumber==i] <- scale(behav$averageExertedRate[behav$subjectNumber==i])
    behav$effortHistory_scaled[behav$subjectNumber==i] <- scale(behav$effortHistory_numeric[behav$subjectNumber==i])
    
  }
}
#write_csv(behav, paste('../data/behavioural/',task_version,'/cleaned_behav_summary_',model_number, task_version,'.csv', sep = ""))

# --------------- COMPARE MIXED MODELS - MAIN EFFECT OF EFFORT --------------------#
# 
# simplest model, to get model matrix, so can specify contrasts manually
# As effortLevel has 3 or more levels, then need to input contrasts manually, which means I can suppress correlations using double pipe ||
# using method in https://www.rpubs.com/Reinhold/22193 and advocated by https://rpubs.com/yjunechoe/correlationsLMEM
d <- behav

m <- glmmTMB(response ~ effortLevel/blockType +
               (effortLevel/blockType|subjectNumber), family = "binomial", data = d)
summary(m) # model does not converge

tmp <- model.matrix(m)
d <- cbind(d, model.matrix(m)[,-1])
data.table::setnames(d, colnames(tmp[,-1]), c('eff2_1', 'eff3_2', 'block_eff_low', 'block_eff_mid', 'block_eff_high'))

models_compare <- data.frame(model_num = double(),
                 rand_effects_structure=character(),
                 convergence=logical(),
                 AIC = double(),
                 stringsAsFactors = FALSE)

models_compare[1:14,]$model_num = c(1:14)
# Different models, going from full model to zero correlation for all random effects model
models_compare[1:14,]$rand_effects_structure <- c(
  # removing correlations
  '(1 + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory||subjectNumber)', # remove correlations for covariates
  '(1 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2||subjectNumber)',
  '(1 + eff2_1 + eff3_2|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  # removing random intercepts
  '(1 + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory||subjectNumber)', # remove correlations for covariates
  '(1 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2||subjectNumber)',
  '(1 + eff2_1 + eff3_2|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',

  '(0 + trialNinBlock_scaled + blockN_scaled + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(0 + trialNinBlock_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(0 + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',

  '(0 + trialNinBlock_scaled  + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(0 + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(0 + blockN_scaled + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)'

)

results <- list()  # Store models
for (i in 1:nrow(models_compare)) {
  # Construct formula dynamically
  random_effects <- models_compare$rand_effects_structure[i]
  formula_str <- paste(
    "response ~ trialNinBlock_scaled + blockN_scaled + responseHistory +",
    "eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + ",
    random_effects
  )

  model_formula <- as.formula(formula_str)

  # Fit the model
  fit <- glmmTMB(model_formula, family = "binomial", data = d)

  # Save results
  results[[i]] <- fit
  tmp <- summary(fit)
}

for (i in 1:nrow(models_compare)) {
  tmp <- summary(results[[i]])
  # Save convergence
  if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
    models_compare$convergence[i] <- 1
  } else {
    models_compare$convergence[i] <- 0
  }
  # Save AIC
  models_compare$AIC[i] <- AIC(results[[i]])

}

main_model <- results[[models_compare$model_num[which.min(models_compare$AIC)]]]
save(results, main_model, models_compare, file = paste0('glmm_output/glm_model_main_', model_number, task_version, '.RData'))


########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

# -------------------------- PREV EFFORT AS FUNCTION OF EFFORT --------------------------#
# --------------- COMPARE MIXED MODELS - MAIN EFFECT OF EFFORT --------------------#
# 
# do not include response history as a covariate, as this makes model unidentifiable (captured by _history predictors)
d <- behav

m <- glmmTMB(response ~ effortLevel/effortHistory_scaled + blockType +
               (effortLevel/effortHistory_scaled + blockType|subjectNumber), family = "binomial", data = d)
summary(m) # model does not converge

tmp <- model.matrix(m)
d <- cbind(d, model.matrix(m)[,-1])
data.table::setnames(d, colnames(tmp[,-1]), c('eff2_1', 'eff3_2', 'block', 'eff_low_history','eff_mid_history','eff_high_history'))

models_compare <- data.frame(model_num = double(),
                             rand_effects_structure=character(),
                             convergence=logical(),
                             AIC = double(),
                             stringsAsFactors = FALSE)

models_compare[1:7,]$model_num = c(1:7)
# Different models, going from full model to zero correlation for all random effects model
models_compare[1:7,]$rand_effects_structure <- c(
  # removing correlations
  '(1 + eff2_1 + eff3_2 + block + eff_low_history + eff_mid_history + eff_high_history|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block + eff_low_history + eff_mid_history + eff_high_history|subjectNumber) + (1 + eff2_1 + eff3_2 + trialNinBlock_scaled + blockN_scaled ||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + eff_low_history + eff_mid_history + eff_high_history|subjectNumber) + (1 + block + trialNinBlock_scaled + blockN_scaled ||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + block + eff_low_history + eff_mid_history + eff_high_history + trialNinBlock_scaled + blockN_scaled||subjectNumber)',

  '(1 + block + eff_low_history + eff_mid_history + eff_high_history|subjectNumber) + (0 + eff2_1 + eff3_2 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + eff_low_history + eff_mid_history + eff_high_history|subjectNumber) + (0 + block + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(0 + eff2_1 + eff3_2 + block + eff_low_history + eff_mid_history + eff_high_history + trialNinBlock_scaled + blockN_scaled||subjectNumber)'
)

results <- list()  # Store models
for (i in 1:nrow(models_compare)) {
  # Construct formula dynamically
  random_effects <- models_compare$rand_effects_structure[i]
  formula_str <- paste("response ~ trialNinBlock_scaled + blockN_scaled + " ,
    "eff2_1 + eff3_2 + block + eff_low_history + eff_mid_history + eff_high_history +",
    random_effects
  )
  
  model_formula <- as.formula(formula_str)
  
  # Fit the model
  fit <- glmmTMB(model_formula, family = "binomial", data = d)
  
  # Save results
  results[[i]] <- fit
  tmp <- summary(fit)
}

for (i in 1:nrow(models_compare)) {
  tmp <- summary(results[[i]])
  # Save convergence
  if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
    models_compare$convergence[i] <- 1
  } else {
    models_compare$convergence[i] <- 0
  }
  # Save AIC
  models_compare$AIC[i] <- AIC(results[[i]])
  
}

prev_eff_model <- results[[models_compare$model_num[which.min(models_compare$AIC)]]]
summary(prev_eff_model)

save(results, prev_eff_model, models_compare, file = paste0('glmm_output/glm_model_prev_', model_number, task_version, '.RData'))

# test the different n trials back models
m2 <- glmmTMB(response ~ effortLevel/averageEffortRate_1 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_1 + blockType + trialNinBlock_scaled + blockN_scaled ||subjectNumber), family = "binomial", data = d)
m3 <- glmmTMB(response ~ effortLevel/averageEffortRate_2 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_2 + blockType + trialNinBlock_scaled + blockN_scaled ||subjectNumber), family = "binomial", data = d)
m4 <- glmmTMB(response ~ effortLevel/averageEffortRate_3 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_3 + blockType + trialNinBlock_scaled + blockN_scaled||subjectNumber), family = "binomial", data = d)
m5 <- glmmTMB(response ~ effortLevel/averageEffortRate_4 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_4 + blockType + trialNinBlock_scaled + blockN_scaled||subjectNumber), family = "binomial", data = d)
m6 <- glmmTMB(response ~ effortLevel/averageEffortRate_5 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_5 + blockType + trialNinBlock_scaled + blockN_scaled||subjectNumber), family = "binomial", data = d)
m7 <- glmmTMB(response ~ effortLevel/averageEffortRate_6 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_6 + blockType + trialNinBlock_scaled + blockN_scaled ||subjectNumber), family = "binomial", data = d)
m8 <- glmmTMB(response ~ effortLevel/averageEffortRate_7 + blockType + trialNinBlock_scaled + blockN_scaled + 
                (effortLevel/averageEffortRate_7 + blockType + trialNinBlock_scaled + blockN_scaled||subjectNumber), family = "binomial", data = d)
AIC(m2,m3,m4,m5,m6,m7,m8)
summary(m7)

#save(m5, file = paste0('glmm_output/glm_model_main_', model_number, task_version, '.RData'))
avg_eff_model <- m7
save(avg_eff_model, file = paste0('glmm_output/glm_model_avg_effort_', model_number, task_version, '.RData'))


# --------------------------------- TEST TRIAL IN BLOCK ---------------------- # 
# d <- behav
# 
# m <- glmmTMB(response ~ effortLevel/trialNinBlock*blockType + 
#                (effortLevel/trialNinBlock*blockType||subjectNumber), family = "binomial", data = d)
# summary(m) # model does not converge
# significant interaction: effortLevelmid:trialNinBlock:blockType2-1 for v1 and V3, not MRI. 
# in MRI, started showing differences from the start. 
#--------------------------------------- MAIN GLM + REWARD COVARIATES -----------------------------#

models_compare <- data.frame(model_num = double(),
                             rand_effects_structure=character(),
                             convergence=logical(),
                             AIC = double(),
                             stringsAsFactors = FALSE)

models_compare[1:15,]$model_num = c(1:15)
# Different models, going from full model to zero correlation for all random effects model
models_compare[1:15,]$rand_effects_structure <- c(
  # removing correlations
  '(1 + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory||subjectNumber)', # remove correlations for covariates
  '(1 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(1 + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(1 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2  + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)',
  '(1 + eff2_1 + eff3_2|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high  + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)',
  '(1 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)',
  # removing random intercepts
  '(1 + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory||subjectNumber)', # remove correlations for covariates
  '(1 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(1 + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high||subjectNumber)',
  '(1 + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)', # remove correlations for covariates
  '(1 + block_eff_low + block_eff_mid + block_eff_high|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)',
  '(1 + eff2_1 + eff3_2|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)',
  '(0 + trialNinBlock_scaled + blockN_scaled + responseHistory + eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + rewardHistory_scaled + averageRewardRate_scaled||subjectNumber)'
)

results <- list()  # Store models
for (i in 1:nrow(models_compare)) {  # ES: We know that model 7 didn't converge (no random correlations for any random effects), so start from model 8
  # Construct formula dynamically
  random_effects <- models_compare$rand_effects_structure[i]
  formula_str <- paste(
    "response ~ trialNinBlock_scaled + blockN_scaled + responseHistory + averageRewardRate + rewardHistory +",
    "eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + ",
    random_effects
  )
  
  model_formula <- as.formula(formula_str)
  
  # Fit the model
  fit <- glmmTMB(model_formula, family = "binomial", data = d)
  
  # Save results
  results[[i]] <- fit
  tmp <- summary(fit)
}

for (i in 1:nrow(models_compare)) {
  tmp <- summary(results[[i]])
  # Save convergence
  if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
    models_compare$convergence[i] <- 1
  } else {
    models_compare$convergence[i] <- 0
  }
  # Save AIC
  models_compare$AIC[i] <- AIC(results[[i]])
  
}

reward_model <- results[[models_compare$model_num[which.min(models_compare$AIC)]]]
save(results, reward_model, models_compare, file = paste0('glmm_output/glm_model_reward_', model_number, task_version, '.RData'))


########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

# --------------- COMPARE MIXED MODELS - EFFECT OF EFFORT HISTORY --------------------#
# d <- behav
# 
# m <- glmmTMB(response ~ blockType*effortHistory +
#                (blockType*effortHistory|subjectNumber), family = "binomial", data = d)
# summary(m)
# 
# tmp <- model.matrix(m)
# d <- cbind(d, model.matrix(m)[,-1])
# data.table::setnames(d, colnames(tmp[,-1]), c('block2_1', 'effHist2_1', 'effHist3_2', 'block_effHist2_1', 'block_effHist3_2'))
# 
# models_compare <- data.frame(model_num = double(),
#                              rand_effects_structure=character(),
#                              convergence=logical(),
#                              AIC = double(),
#                              stringsAsFactors = FALSE)
# 
# models_compare[1:14,]$model_num = c(1:14)
# # Different models, going from full model to zero correlation for all random effects model
# models_compare[1:14,]$rand_effects_structure <- c(
#   # removing correlations
#   '(1 + block2_1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (1 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1 + effHist2_1 + effHist3_2|subjectNumber) + (1 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (1 + trialNinBlock_scaled + responseHistory + blockN_scaled + effHist2_1 + effHist3_2||subjectNumber)',
#   '(1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (1 + block2_1 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1|subjectNumber) + (1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + effHist2_1 + effHist3_2|subjectNumber) + (1 + block2_1 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
# 
#   # removing random intercepts
#   '(1 + block2_1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (0 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1 + effHist2_1 + effHist3_2|subjectNumber) + (0 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (0 + trialNinBlock_scaled + responseHistory + blockN_scaled + effHist2_1 + effHist3_2||subjectNumber)',
#   '(1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2|subjectNumber) + (0 + block2_1 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + block2_1|subjectNumber) + (0 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + effHist2_1 + effHist3_2|subjectNumber) + (0 + block2_1 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(0 + block2_1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)'
# )
# 
# results <- list()  # Store models
# for (i in 1:nrow(models_compare)) {
#   # Construct formula dynamically
#   random_effects <- models_compare$rand_effects_structure[i]
#   formula_str <- paste(
#     "response ~ block2_1 + effHist2_1 + effHist3_2 + block_effHist2_1 + block_effHist3_2 + trialNinBlock_scaled + responseHistory + blockN_scaled + ",
#     random_effects
#   )
# 
#   model_formula <- as.formula(formula_str)
# 
#   # Fit the model
#   fit <- glmmTMB(model_formula, family = "binomial", data = d)
# 
#   # Save results
#   results[[i]] <- fit
#   tmp <- summary(fit)
# }
# 
# for (i in 1:nrow(models_compare)) {
#   tmp <- summary(results[[i]])
#   # Save convergence
#   if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
#     models_compare$convergence[i] <- 1
#   } else {
#     models_compare$convergence[i] <- 0
#   }
#   # Save AIC
#   models_compare$AIC[i] <- AIC(results[[i]])
# 
# }
# 
# prev_eff_model <- results[[models_compare$model_num[which.min(models_compare$AIC)]]]
# save(results, prev_eff_model, models_compare, file = paste0('glmm_output/glm_model_prev_eff_', model_number, task_version, '.RData'))

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

# --------------- COMPARE MIXED MODELS - EFFECT OF EXERTED EFFORT HISTORY --------------------#
d <- behav

m <- glmmTMB(response ~ blockType*exertedEffortHistory +
               (blockType*exertedEffortHistory|subjectNumber), family = "binomial", data = d)
summary(m)

tmp <- model.matrix(m)
d <- cbind(d, model.matrix(m)[,-1])
data.table::setnames(d, colnames(tmp[,-1]), c('block2_1','exertHist2_1', 'exertHist3_2', 'exertHist4_3', 'block_exertHist2_1', 'block_exertHist3_2', 'block_exertHist4_3'))

models_compare <- data.frame(model_num = double(),
                             rand_effects_structure=character(),
                             convergence=logical(),
                             AIC = double(),
                             stringsAsFactors = FALSE)

models_compare[1:14,]$model_num = c(1:14)
# Different models, going from full model to zero correlation for all random effects model
models_compare[1:14,]$rand_effects_structure <- c(
  # removing correlations
  '(1 + block2_1 + exertHist2_1 + exertHist3_2 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3|subjectNumber) + (1 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (1 + trialNinBlock_scaled + blockN_scaled + exertHist2_1 + exertHist3_2 + exertHist4_3||subjectNumber)',
  '(1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (1 + block2_1 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1|subjectNumber) + (1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + exertHist2_1 + exertHist3_2 + exertHist4_3|subjectNumber) + (1 + block2_1 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',

  # removing random intercepts
  '(1 + block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3|subjectNumber) + (0 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (0 + trialNinBlock_scaled + blockN_scaled + exertHist2_1 + exertHist3_2 + exertHist4_3||subjectNumber)',
  '(1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3|subjectNumber) + (0 + block2_1 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + block2_1|subjectNumber) + (0 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(1 + exertHist2_1 + exertHist3_2 + exertHist4_3|subjectNumber) + (0 + block2_1 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)',
  '(0 + block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled||subjectNumber)'
)

results <- list()  # Store models
for (i in 1:nrow(models_compare)) {
  # Construct formula dynamically
  random_effects <- models_compare$rand_effects_structure[i]
  formula_str <- paste(
    "response ~ block2_1 + exertHist2_1 + exertHist3_2 + exertHist4_3 + block_exertHist2_1 + block_exertHist3_2 + block_exertHist4_3 + trialNinBlock_scaled + blockN_scaled + ",
    random_effects
  )

  model_formula <- as.formula(formula_str)

  # Fit the model
  fit <- glmmTMB(model_formula, family = "binomial", data = d)

  # Save results
  results[[i]] <- fit
  tmp <- summary(fit)
}

for (i in 1:nrow(models_compare)) {
  tmp <- summary(results[[i]])
  # Save convergence
  if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
    models_compare$convergence[i] <- 1
  } else {
    models_compare$convergence[i] <- 0
  }
  # Save AIC
  models_compare$AIC[i] <- AIC(results[[i]])

}

exert_eff_model <- results[[models_compare$model_num[which.min(models_compare$AIC)]]]
save(results, exert_eff_model, models_compare, file = paste0('glmm_output/glm_model_exert_eff_', model_number, task_version, '.RData'))

#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################

# # --------------- COMPARE MIXED MODELS - EFFECT OF AVERAGE EFFORT  --------------------#
## NOTE: n trials back is + 1, so _1_ is actually average of last two trials. 
# d <- behav
# 
# models_compare <- data.frame(model_num = double(),
#                              rand_effects_structure=character(),
#                              convergence=logical(),
#                              AIC = double(),
#                              stringsAsFactors = FALSE)
# 
# models_compare[1:14,]$model_num = c(1:14)
# # Different models, going from full model to zero correlation for all random effects model
# 
# # Best model is average_4_, which is equivalent to 5 trials back, because of the way movmean calculation works 
# models_compare[1:14,]$rand_effects_structure <- c(
#   # removing correlations
#   '(1 + blockType*averageEffortRate_4_scaled|subjectNumber) + (1 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType + averageEffortRate_4_scaled|subjectNumber) + (1 + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType +  blockType:averageEffortRate_4_scaled|subjectNumber) + (1 + trialNinBlock_scaled + responseHistory + blockN_scaled + averageEffortRate_4_scaled||subjectNumber)',
#   '(1 + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled|subjectNumber) + (1 + blockType + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType|subjectNumber) + (1 + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + averageEffortRate_4_scaled|subjectNumber) + (1 + blockType + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
# 
#   # removing random intercepts
#   '(1 + blockType + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled|subjectNumber) + (0 + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType + averageEffortRate_4_scaled|subjectNumber) + (0 + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType + blockType:averageEffortRate_4_scaled|subjectNumber) + (0 + trialNinBlock_scaled + responseHistory + blockN_scaled + averageEffortRate_4_scaled||subjectNumber)',
#   '(1 + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled|subjectNumber) + (0 + blockType + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + blockType|subjectNumber) + (0 + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(1 + averageEffortRate_4_scaled|subjectNumber) + (0 + blockType + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)',
#   '(0 + blockType + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled||subjectNumber)'
# )
# 
# results <- list()  # Store models
# for (i in 1:nrow(models_compare)) {
#   # Construct formula dynamically
#   random_effects <- models_compare$rand_effects_structure[i]
#   formula_str <- paste(
#     "response ~ blockType + averageEffortRate_4_scaled + blockType:averageEffortRate_4_scaled + trialNinBlock_scaled + responseHistory + blockN_scaled + ",
#     random_effects
#   )
# 
#   model_formula <- as.formula(formula_str)
# 
#   # Fit the model
#   fit <- glmmTMB(model_formula, family = "binomial", data = d)
# 
#   # Save results
#   results[[i]] <- fit
#   tmp <- summary(fit)
# }
# 
# for (i in 1:nrow(models_compare)) {
#   tmp <- summary(results[[i]])
#   # Save convergence
#   if (length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0) {
#     models_compare$convergence[i] <- 1
#   } else {
#     models_compare$convergence[i] <- 0
#   }
#   # Save AIC
#   models_compare$AIC[i] <- AIC(results[[i]])
# 
# }

# #  ----------------------------- MODEL DIAGNOSTICS 
# # # outliers
# # sum(abs(resid(win_model, scaled = TRUE)) > 2) / length(resid(win_model))  # 1.8%
# # sum(abs(resid(win_model, scaled = TRUE)) > 2.5) / length(resid(win_model))  # 0.3%
# # sum(abs(resid(win_model, scaled = TRUE)) > 3.5) / length(resid(win_model))  # 0%
# #
# # # autocorrelation
# # plot(acf(d$response))
# # plot(acf(resid(win_model)))
# 
# # # normality
# # qqmath(resid(model,scaled=TRUE))
# 
# 
# 
# # --------------------------- look at trial N in block interaction with blockContrasts_mid ---------------# 
# # significant interaction for v1 and v3, but not for MRI. 
# # fit <- glmmTMB(response ~ trialNinBlock_scaled:blockContrasts_mid + trialNinBlock_scaled + blockN_scaled + responseHistory +
# #                  eff2_1 + eff3_2 + block_eff_low + block_eff_mid + block_eff_high + (1 + eff2_1 + eff3_2|subjectNumber) + 
# #                  (1 + trialNinBlock_scaled:blockContrasts_mid + trialNinBlock_scaled + blockN_scaled + responseHistory + block_eff_low + block_eff_mid + block_eff_high||subjectNumber), 
# #                family = "binomial", data = d)
