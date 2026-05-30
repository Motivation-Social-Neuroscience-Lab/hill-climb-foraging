# AET - analysis and visualiation
# Emma Scholey 27 May 2026 

# SETUP ################ 
rm(list = ls(all = TRUE)) # clear environment

# load packages - install.packages("package") if not installed already
library(tidyverse)
library(ggsci)
library(ggpubr)
library(glmmTMB)
library(ggtext)
library(xtable)
library(broom.mixed)
library(MASS)
library(sjPlot)

setwd('~/Dropbox/average-effort/code/behavioural_analysis/') # adjust as required

# select the data you want to analyse

task_version = 'v3' # v1, v3 or mri
model_number = '' #If running statistics on simulated data, include model_number + underscore (e.g. 'M6_'). If not, then leave blank ('')

d <- read.csv(paste('../data/behavioural/',task_version,'/cleaned_behav_summary_',model_number, task_version,'.csv', sep = ""))

# set factors
d$effortLevel <- factor(d$effortLevel, levels = c("low", "mid", "high"), labels = c("low", "mid", "high"), ordered = T)  
d$blockType <- factor(d$blockType, levels = c("easy", "hard"), labels = c("easy", "hard"))

d$effortHistory <- factor(d$effortHistory, levels = c("low", "mid", "high"), labels = c("low", "mid", "high"), ordered = T)  
d$responseHistory <- factor(d$responseHistory, levels = c('wait', 'accept'), labels = c('wait', 'accept'), ordered = T)

contrasts(d$effortLevel) <- contr.sdif(3) # repeated contrasts ('sliding differences')
contrasts(d$effortHistory) <- contr.sdif(3)
contrasts(d$blockType) <- contr.sdif(2) # same as coding block type as 0.5 or -0.5
contrasts(d$responseHistory) <- contr.sdif(2)


pd <- position_jitter(height = 0, width = 0.1, seed = 123)
source('../figures/functions/ggplot_style_file.R')

#---------------------------------- Helper Functions ---------------------
# HELPER: fit a set of glmmTMB models that share fixed effects but
# differ in their random-effects structure. Returns the fitted models
# and a comparison table; winner selection is done by the caller so
# you can inspect models_compare and apply intuition where needed.
#
# Arguments:
#   fixed_effects        : RHS-only fixed-effects string (no leading "response ~"),
#                          e.g. "trialNinBlock_scaled + blockN_scaled + effortLevel/blockType"
#   random_effects_list  : character vector of random-effects formulas, each of the
#                          form "(...|subjectNumber)" / "diag(...|subjectNumber)" etc.
#   data                 : data frame
#
# Returns a list with: results, models_compare.

fit_model_set <- function(fixed_effects, random_effects_list, data) {
  
  models_compare <- data.frame(
    model_num               = seq_along(random_effects_list),
    rand_effects_structure  = random_effects_list,
    convergence             = NA,
    singular                = NA_integer_,
    AIC                     = NA_real_,
    stringsAsFactors        = FALSE
  )
  
  results <- vector("list", length(random_effects_list))
  
  for (i in seq_along(random_effects_list)) {
    formula_str <- paste("response ~", fixed_effects, "+", random_effects_list[i])
    fit <- glmmTMB(as.formula(formula_str), family = "binomial", data = data)
    results[[i]] <- fit
    
    tmp <- summary(fit)
    models_compare$convergence[i] <- as.integer(length(tmp[["optinfo"]][["conv"]][["lme4"]]) == 0)
    models_compare$singular[i]    <- as.integer(performance::check_singularity(fit))
    models_compare$AIC[i]         <- AIC(fit)
  }
  
  list(results = results, models_compare = models_compare)
}
#------------------ SUMMARY descriptives -------------
# N trials
tmp <- d %>% group_by(subjectNumber) %>% 
  summarise(trials = max(trialN))

# N trials and credits in each environment
d.nAccept <- d  %>%
  group_by(subjectNumber, blockType) %>%
  summarise(acceptRate = mean(response), total_credits = sum(reward))
t.test(d.nAccept$acceptRate[d.nAccept$blockType == 'easy'], d.nAccept$acceptRate[d.nAccept$blockType == 'hard'], paired = TRUE)
mean(d.nAccept$acceptRate[d.nAccept$blockType == 'easy'])
mean(d.nAccept$acceptRate[d.nAccept$blockType == 'hard'])
sd(d.nAccept$acceptRate[d.nAccept$blockType == 'easy'])
sd(d.nAccept$acceptRate[d.nAccept$blockType == 'hard'])

t.test(d.nAccept$total_credits[d.nAccept$blockType == 'easy'], d.nAccept$total_credits[d.nAccept$blockType == 'hard'], paired = TRUE)
mean(d.nAccept$total_credits[d.nAccept$blockType == 'easy'])
mean(d.nAccept$total_credits[d.nAccept$blockType == 'hard'])
sd(d.nAccept$total_credits[d.nAccept$blockType == 'easy'])
sd(d.nAccept$total_credits[d.nAccept$blockType == 'hard'])

#------------------ MIXED MODELS --------------
##--------------- Main effort --------------------
main_random_effects <- c(
  # removing correlations
  '(1 + effortLevel/blockType|subjectNumber) + diag(1 + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)', # remove correlations for covariates
  'diag(1 + trialNinBlock_scaled + blockN_scaled + responseHistory + effortLevel/blockType|subjectNumber)',
  'diag(1 + blockN_scaled + responseHistory + effortLevel + blockType|subjectNumber)',
  
  # removing random intercepts
  '(1 + effortLevel/blockType|subjectNumber) + diag(0 + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)',
  'diag(0 + trialNinBlock_scaled + blockN_scaled + responseHistory + effortLevel/blockType|subjectNumber)',
  
  'diag(0 + trialNinBlock_scaled + blockN_scaled + effortLevel/blockType|subjectNumber)',
  'diag(0 + trialNinBlock_scaled + responseHistory + effortLevel/blockType|subjectNumber)',
  'diag(0 + blockN_scaled + responseHistory + effortLevel/blockType|subjectNumber)',
  
  'diag(0 + trialNinBlock_scaled + effortLevel/blockType|subjectNumber)',
  'diag(0 + responseHistory + effortLevel/blockType|subjectNumber)',
  'diag(0 + blockN_scaled + effortLevel/blockType|subjectNumber)'
)

main_out <- fit_model_set(
  fixed_effects       = "trialNinBlock_scaled + blockN_scaled + responseHistory + effortLevel/blockType",
  random_effects_list = main_random_effects,
  data                = d
)

results        <- main_out$results
models_compare <- main_out$models_compare
print(models_compare)

# Pick winner (override per task_version with intuition if needed)
if (model_number== ''){ # for empirical data
  main_idx <- case_when(
    task_version == 'mri' ~ 2,
    task_version == 'v3' ~  3, 
    task_version == 'v1' ~ 2
  )
} else {
  main_idx <- case_when( # for model simulated data
    task_version == 'mri' ~ 10,
    task_version == 'v3' ~  9, 
    task_version == 'v1' ~ 3
  )
}

main_model <- results[[main_idx]]
summary(main_model)
save(results, main_model, models_compare,
     file = paste0('glmm_output/glm_model_main_', model_number, task_version, '.RData'))


#------------------------------ Accept rate
d.accept.rate <- d %>% group_by(subjectNumber, blockType, effortLevel) %>% summarise(acceptRate = mean(response))
# Combine blockType and effortLevel into a single factor for grouping on the x-axis
d.accept.rate$grouping <- as.factor(interaction(d.accept.rate$blockType, d.accept.rate$effortLevel, sep = " - "))

image <- ggplot2::ggplot(d.accept.rate, aes(x = grouping, y = acceptRate, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,effortLevel)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,effortLevel), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) +
  labs(x = "effort", y = "pr(accept)") +
  theme_classic() +
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image

# extract p-values from glm object
p_values <- summary(main_model)$coefficients$cond[c("effortLevel2-1", 'effortLevel3-2', 'effortLevellow:blockType2-1', 'effortLevelmid:blockType2-1', 'effortLevelhigh:blockType2-1'), "Pr(>|z|)"]
sig <- array(NA,c(5,length(p_values)))

for (c in 1:ncol(sig)) {
  if (p_values[c] < .001)
  {sig[1,c] <- "< .001"
  } else if (p_values[c] >= .05) 	{sig[1,c] <- "ns."
  } else if (p_values[c] < .05 & p_values[c] >= .001)	{sig[1,c] <- as.character(round(p_values[c],3))}
}

sig[2,] <- c(1.15, 1.15, 1.05, 1.05, 1.05)
sig[3,] <- c(1.5, 3.6, 1, 3, 5)
sig[4,] <- c(3.4, 5.5, 2, 4, 6)
sig[5,] <- c(0.02, 0.02, 0, 0, 0)

for (c in 1:ncol(sig)){
  image <- image + geom_signif(annotation = sig[1,c], y_position = as.numeric(sig[2,c]),
                               xmin = as.numeric(sig[3,c]), xmax = as.numeric(sig[4,c]),
                               tip_length = as.numeric(sig[5,c]),
                               colour = 'black', textsize = figure$p_label_size, size = 0.3)}

if (model_number != ''){
  image <- image +
    scale_y_continuous(name = "pr(accept)<br><span style='font-size:8pt; font-style:italic;'>simulated</span>") +
    theme(axis.title.y=element_markdown(size = figure$font_size))
}
image

# save
ggsave(file = paste0('../figures/plots/', task_version, '/', model_number, 'accept_rate.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# output table of odds ratios and p-values
# get likelihood profile CI rather than Wald (more accurate but takes a while
# check profile CIs don't go through 1 (OR)
tmp <- tidy(main_model, conf.int = T, conf.method="profile", exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Trial number in block', 'Block number', 'Previous choice', 'Effort offer (mid - low)', 'Effort offer (high - mid)', 'Low effort: hard - easy', 'Mid effort: hard - easy', 'High effort: hard - easy')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'main_glm_table.tex'))


if (model_number== ''){ # rest of analysis script is for empirical data only, not for simulated model data 
  ##-------------------------- Average effort --------------------------
  avg_eff_random_effects <- c(
    '(1 + effortLevel/averageEffortRate_4_scaled|subjectNumber) + diag(1 + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)',
    'diag(1 + effortLevel/averageEffortRate_4_scaled + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)',
    
    'diag(1 + effortLevel/averageEffortRate_4_scaled|subjectNumber) + diag(0 + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)',
    'diag(0 + effortLevel/averageEffortRate_4_scaled + trialNinBlock_scaled + blockN_scaled + responseHistory|subjectNumber)',
    '(1 + effortLevel/averageEffortRate_4_scaled|subjectNumber)',
    'diag(1 + effortLevel/averageEffortRate_4_scaled|subjectNumber)',
    'diag(0 + effortLevel/averageEffortRate_4_scaled|subjectNumber)'
  )
  
  avg_eff_out <- fit_model_set(
    fixed_effects       = "effortLevel/averageEffortRate_4_scaled + trialNinBlock_scaled + blockN_scaled + responseHistory",
    random_effects_list = avg_eff_random_effects,
    data                = d
  )
  
  results        <- avg_eff_out$results
  models_compare <- avg_eff_out$models_compare
  print(models_compare)
  
  # Pick winner (override per task_version with intuition if needed)
  avg_eff_idx <- case_when(
    task_version == 'mri' ~ 2,
    task_version == 'v3' ~  2, # check model 6 for non-singular term
    task_version == 'v1' ~ 2 # check model 6 for non-singular terms
  )
  
  # Pick winner (override per task_version with intuition if needed)
  avg_eff_model <- results[[avg_eff_idx]]
  summary(avg_eff_model)
  save(results, avg_eff_model, models_compare,
       file = paste0('glmm_output/glm_model_avg_eff_', model_number, task_version, '.RData'))
  
  image <- ggplot2::ggplot(d, aes(x = averageEffortRate_4_scaled, y = response, colour = effortLevel)) +
    geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial')) + 
    scale_colour_manual(values = c("#7E57C2", "#00695C", "#F06292")) +
    coord_cartesian(ylim = c(0, 1.2)) +
    scale_y_continuous(breaks = seq(0, 1, 0.2)) +
    labs(x = "avg. effort (t-5) [z]", y = "pr(accept)") +
    facet_wrap(vars(effortLevel)) +
    theme_classic() +
    theme(legend.title = element_blank(), legend.position = "none", text = element_text(size = figure$font_size))
  image
  
  # load and extract p-values from glm object
  p_values <- summary(avg_eff_model)$coefficients$cond[c("effortLevellow:averageEffortRate_4_scaled", 'effortLevelmid:averageEffortRate_4_scaled', 'effortLevelhigh:averageEffortRate_4_scaled'), "Pr(>|z|)"]
  ## Turn into printable labels (ns / < .001 / numeric)
  p_labs <- vapply(p_values, function(p) {
    if (p < .001) { "p < .001"} else if (p >= .05) { "ns." } else {paste0("p = ", as.character(round(p, 3)))
    }
  }, character(1))
  
  p_dat <- data.frame(
    effortLevel = sort(unique(d$effortLevel)),  # facet variable
    label = unname(p_labs),
    group1 = "a", group2 = "b",
    xmin = 0.4,
    xmax = 0.4,
    y.position = 1.05
  )
  
  image <- image +
    stat_pvalue_manual(
      p_dat,
      label = "label",          # column with the formatted text
      y.position = "y.position",
      xmin = "xmin",
      xmax = "xmax",
      remove.bracket = TRUE  , 
      size = figure$p_label_size)
  
  image
  
  ggsave(file = paste0('../figures/plots/', task_version, '/', model_number, 'avg_effort_within_effort.pdf'), plot = image, width = figure$width*2.3, height = 5, unit = 'cm', device = "pdf", bg = "transparent")
  
  tmp <- tidy(avg_eff_model, conf.int = T, conf.method="profile", exponentiate = T, effects = 'fixed')
  tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
  colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
  tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
  tmp[,c(1)] <- c('(Intercept)','Effort offer (mid - low)', 'Effort offer (high - mid)','Trial number in block', 'Block number', 'Previous choice','Low effort: Average effort encountered', 'Mid effort: Average effort encountered', 'High effort: Average effort encountered')
  latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
  print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'prev_avg_effort_glm_table.tex'))
  
  ##--------------------------------------- Reward -----------------------------
  
  reward_random_effects <- c(
    'diag(1 + trialNinBlock_scaled + blockN_scaled + effortLevel/blockType + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber)',
    
    '(0 + effortLevel/blockType + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber) + diag(0 + trialNinBlock_scaled + blockN_scaled|subjectNumber)',
    '(0 + effortLevel/blockType + rewardHistory_scaled |subjectNumber) + diag(0 + averageRewardRate_scaled + trialNinBlock_scaled + blockN_scaled|subjectNumber)',
    '(0 + effortLevel/blockType + averageRewardRate_scaled|subjectNumber) + diag(0 + rewardHistory_scaled + trialNinBlock_scaled + blockN_scaled|subjectNumber)',
    
    'diag(0 + trialNinBlock_scaled + blockN_scaled + effortLevel/blockType + rewardHistory_scaled + averageRewardRate_scaled|subjectNumber)',
    'diag(1 + trialNinBlock_scaled + blockN_scaled + effortLevel + blockType + averageRewardRate_scaled|subjectNumber)',
    'diag(1 + blockN_scaled + effortLevel + blockType + averageRewardRate_scaled|subjectNumber)'
  )
  
  reward_out <- fit_model_set(
    fixed_effects       = "trialNinBlock_scaled + blockN_scaled + responseHistory + averageRewardRate + rewardHistory + effortLevel/blockType",
    random_effects_list = reward_random_effects,
    data                = d
  )
  
  results        <- reward_out$results
  models_compare <- reward_out$models_compare
  print(models_compare)
  
  # Pick winner (override per task_version with intuition if needed)
  reward_idx <- case_when(
    task_version == 'mri' ~ 1,
    task_version == 'v3' ~  7, 
    task_version == 'v1' ~ 1
  )
  reward_model <- results[[reward_idx]]
  summary(reward_model)
  # V3 cross-check vs model 7 (drops singular terms):
  # summary(results[[7]])
  save(results, reward_model, models_compare,
       file = paste0('glmm_output/glm_model_reward_', model_number, task_version, '.RData'))
  
  tmp <- tidy(reward_model, conf.int = T, conf.method="profile", exponentiate = T, effects = 'fixed')
  tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
  colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
  tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
  tmp[,c(1)] <- c('(Intercept)','Trial number in block', 'Block number', 'Previous choice', 'Average reward', 'Previous reward', 'Effort offer (mid - low)', 'Effort offer (high - mid)', 'Low effort: hard - easy', 'Mid effort: hard - easy', 'High effort: hard - easy')
  latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
  print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'reward_glm_table.tex'))
  
  
  
  ## --------------------------- Model parameters ----------------------- 
  model_params <- if (task_version == 'mri') {
    read.csv(paste('../data/fit/', task_version, '/fit_params_M1.csv', sep = ""))
  } else if (task_version == 'v1') {
    read.csv(paste('../data/fit/', task_version, '/fit_params_M1.csv', sep = ""))
  } else if (task_version == 'v3') {
    read.csv(paste('../data/fit/', task_version, '/fit_params_M2.csv', sep = ""))
  }
  
  d.opp.cost <- d %>%
    filter(effortLevel == 'mid') %>%
    group_by(subjectNumber, blockType) %>%
    summarise(acceptRate = mean(response)) %>%
    ungroup()
  
  
  tmp <- d.opp.cost$acceptRate[d.opp.cost$blockType == 'hard'] - d.opp.cost$acceptRate[d.opp.cost$blockType == 'easy']
  
  d.accept.rate.params <- d %>%
    group_by(subjectNumber) %>%
    summarise(acceptRate = mean(response)) %>% cbind(model_params)
  
  d.accept.rate.params$opp_cost <- tmp
  
  corr_matrix <- cor(d.accept.rate.params)
  
  cor_test <- psych::corr.test(d.accept.rate.params)$p
  
  corrplot::corrplot(
    corr_matrix,
    p.mat = cor_test,
    sig.level = 0.05,
    insig = "blank",
    type = "lower",     # Display lower triangle of the matrix
    tl.col = "black",     # Color of variable names
    tl.cex = 1          # Adjust the font size of variable names
  )
  
  # Alpha-Kappa correlation
  image <- ggplot(d.accept.rate.params, aes(x = kOffer, y = alpha)) +
    geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
    geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = figure$subj_point_size, stroke = 0.1) +
    xlab('discount: ') + ylab('alpha') +
    geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) +
    theme_classic() +
    stat_cor(method = 'pearson', p.digits = 2, size = 3.5, label.y = 0.7) +
    theme(text = element_text(size = figure$font_size))
  image
  
  # Alpha-Beta correlation
  image <- ggplot(d.accept.rate.params, aes(x = beta, y = alpha)) +
    geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
    geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = figure$subj_point_size, stroke = 0.1) +
    xlab('beta ') + ylab('alpha') +
    geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) +
    theme_classic() +
    stat_cor(method = 'pearson', p.digits = 2, size = 3.5, label.y = 0.7) +
    theme(text = element_text(size = figure$font_size))
  image
  
  # Discount parameter
  image <- ggplot(d.accept.rate.params, aes(x = kOffer, y = opp_cost)) +
    geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
    geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = figure$subj_point_size, stroke = 0.1) +
    xlab('discount: ') + ylab('pr(accept): hard - easy') +
    geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) +
    theme_classic() +
    ylim(c(-0.2,0.8)) +
    stat_cor(method = 'pearson', p.digits = 2, size = 3.5, label.y = 0.7) +
    theme(text = element_text(size = figure$font_size))
  image
  ggsave(file = paste0('../figures/plots/', task_version, '/', 'k_opp_cost_correlation', '.pdf'), plot = image, width = 6, height = 6, unit = 'cm', device = "pdf", bg = "transparent")
  
  # for alpha, do log or spearmans since skewed
  image <- ggplot(d.accept.rate.params, aes(x = log(alpha), y = opp_cost)) +
    geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
    geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = figure$subj_point_size, stroke = 0.1) +
    xlab('log(learning rate)') + ylab('pr(accept): hard - easy') +
    geom_smooth(method='lm', formula= y ~ x, colour = figure$colour_model, linewidth = 0.4) +
    theme_classic() +
    ylim(c(-0.2,0.8)) +
    stat_cor(method = 'pearson', p.digits = 2, size = 3.5, label.y = 0.7) +
    theme(text = element_text(size = figure$font_size))
  image
  ggsave(file = paste0('../figures/plots/', task_version, '/', 'alpha_opp_cost_correlation', '.pdf'), plot = image, width = 6, height = 6, unit = 'cm', device = "pdf", bg = "transparent")
  
  # softmax temperature
  image <- ggplot(d.accept.rate.params, aes(x = beta, y = opp_cost)) +
    geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
    geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = figure$subj_point_size, stroke = 0.1) +
    xlab('softmax temperature') + ylab('pr(accept): hard - easy') +
    geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) +
    theme_classic() +
    ylim(c(-0.2,0.8)) +
    stat_cor(method = 'pearson', p.digits = 2, size = 3.5, label.y = 0.7) +
    theme(text = element_text(size = figure$font_size))
  image
  ggsave(file = paste0('../figures/plots/', task_version, '/', 'beta_opp_cost_correlation', '.pdf'), plot = image, width = 6, height = 6, unit = 'cm', device = "pdf", bg = "transparent")
}