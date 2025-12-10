# AET - behaviour plots
# Emma Scholey 5 Dec 24 

# SETUP ################ 
rm(list = ls(all = TRUE)) # clear environment

# load packages
library(tidyverse)
library(ggsci)
library(ggpubr)
library(glmmTMB)
library(ggtext)
library(xtable)
library(broom.mixed)

setwd('~/Dropbox/average-effort/code/analysis/') # adjust as required

# select the data you want to analyse

task_version = 'v3' # v1, v3 or mri
model_number = '' #If running statistics on simulated data, include model_number + underscore (e.g. 'M6_'). If not, then leave blank ('')

d <- read.csv(paste('../data/behavioural/',task_version,'/cleaned_behav_summary_',model_number, task_version,'.csv', sep = ""))

# set the factor levels

d$effortLevel <- factor(d$effortLevel, levels = c("low", "mid", "high"), labels = c("low", "mid", "high"), ordered = T)  
d$blockType <- factor(d$blockType, levels = c("easy", "hard"), labels = c("easy", "hard"))

d$effortHistory <- factor(d$effortHistory, levels = c("low", "mid", "high"), labels = c("low", "mid", "high"), ordered = T)  
d$exertedEffortHistory <- factor(d$exertedEffortHistory, levels = c("wait", "low", "mid", "high"), labels = c("wait", "low", "mid", "high"), ordered = T)  

d$responseHistory <- factor(d$responseHistory, levels = c('wait', 'accept'), labels = c('wait', 'accept'), ordered = T)

pd <- position_jitter(height = 0, width = 0.1, seed = 123)

tmp <- d %>% group_by(subjectNumber) %>% 
  summarise(trials = max(trialN))


#d <- d %>% filter(subjectNumber %in% c(2, 13+1, 31+2, 38+2))# MRI high beta - actual
#d <- d %>% filter(subjectNumber %in% c(2, 13, 31, 38))# MRI high beta - model

#d <- d %>% filter(subjectNumber %in% c(7+2, 11+2, 28+7, 35+9))# V1 high beta - actual
#d <- d %>% filter(subjectNumber %in% c(7, 11, 28, 35))#  V1 high beta - model

#d <- d %>% filter(subjectNumber %in% c(7+16, 8+16, 18+18, 20+18, 26+19, 31+19))# V3 high beta - actual
#d <- d %>% filter(subjectNumber %in% c(7, 8, 18, 20, 26, 31))# V3 high beta - model

source('../../figures/functions/ggplot_style_file.R')

#d <- d %>% filter( !subjectNumber %in% c(3, 5, 36))

# # calculate mean experienced reward/effort for initialising background estimates in computational models
# exp_eff <- d %>% mutate(exerted_effort = effort/111*response) %>% group_by(subjectNumber) %>% summarise(eff = mean(exerted_effort)) %>% summarise(mean(eff))
# exp_rew <- d %>% group_by(subjectNumber) %>% summarise(rew = mean(response*2)) %>% summarise(mean(rew))
#----------------------------------------------------- ACCEPT RATE ---------------------------------------------------# 
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
# load and extract p-values from glm object
load(file = paste0('glmm_output/glm_model_main_', model_number, task_version, '.RData'))

p_values <- summary(main_model)$coefficients$cond[c("eff2_1", 'eff3_2', 'block_eff_low', 'block_eff_mid', 'block_eff_high'), "Pr(>|z|)"]
sig <- array(NA,c(5,length(p_values)))

for (c in 1:ncol(sig)) {
  if (p_values[c] < .001)
  {sig[1,c] <- "< .001"
  } else if (p_values[c] >= .05) 	{sig[1,c] <- "ns."
  } else if (p_values[c] < .05 & p_values[c] >= .001)	{sig[1,c] <- as.character(round(p_values[c],3))}
}

sig[2,] <- c(1.15, 1.15, 1.05, 1.05, 0.25)
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
ggsave(file = paste0('plots/', task_version, '/', model_number, 'accept_rate.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# output table of odds ratios and p-values

tmp <- tidy(main_model, conf.int = T, exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Trial number in block', 'Block number', 'Previous choice', 'Effort offer (mid - low)', 'Effort offer (high - mid)', 'Low effort: hard - easy', 'Mid effort: hard - easy', 'High effort: hard - easy')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'main_glm_table.tex'))

#----------------------------------------------------- EFFORT CUE (t-1) ---------------------------------------------------# 
d.accept.rate.effHist <- d %>% filter(effortLevel == 'high') %>% group_by(subjectNumber, effortHistory) %>% summarise(acceptRate = mean(response))

image <- ggplot2::ggplot(d.accept.rate.effHist, aes(x = effortHistory, y = acceptRate)) +
  geom_path(aes(group = subjectNumber), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = subjectNumber), position = pd, shape = 21, size = figure$subj_point_size, fill = figure$colour_subj_effort, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size, colour = figure$colour_effort) +
  stat_summary(aes(y = acceptRate, group = 1), fun.y = "mean", geom = "line", colour = figure$colour_effort) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  labs(x = "effort offer (t-1)", y = "pr(accept)") +
  theme_classic() +
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
# load and extract p-values from glm object
load(file = paste0('glmm_output/glm_model_prev_eff_', model_number, task_version, '.RData'))

p_values <- summary(prev_eff_model)$coefficients$cond[c("effHist2_1", 'effHist3_2'), "Pr(>|z|)"]
sig <- array(NA,c(5,length(p_values)))

for (c in 1:ncol(sig)) {
  if (p_values[c] < .001)
  {sig[1,c] <- "< .001"
  } else if (p_values[c] >= .05) 	{sig[1,c] <- "ns."
  } else if (p_values[c] < .05 & p_values[c] >= .001)	{sig[1,c] <- as.character(round(p_values[c],3))}
}

sig[2,] <- c(1.05, 1.05)
sig[3,] <- c(1, 2.1)
sig[4,] <- c(1.9, 3)
sig[5,] <- c(0.0, 0.0)

for (c in 1:ncol(sig)){
  image <- image + geom_signif(annotation = sig[1,c], y_position = as.numeric(sig[2,c]),
                               xmin = as.numeric(sig[3,c]), xmax = as.numeric(sig[4,c]),
                               tip_length = as.numeric(sig[5,c]),
                               colour = 'black', textsize = figure$p_label_size)}

if (model_number != ''){
  image <- image +
    scale_y_continuous(name = "pr(accept)<br><span style='font-size:8pt; font-style:italic;'>simulated</span>") +
    theme(axis.title.y=element_markdown(size = figure$font_size))
}
image
ggsave(file = paste0('plots/', task_version, '/', model_number, 'accept_rate_eff_history.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

tmp <- tidy(prev_eff_model, conf.int = T, exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Environment', 'Previous offer (mid - low)', 'Previous offer (high - mid)','Environment:Previous offer (mid - low)', 'Environment:Previous offer (high - mid)','Trial number in block', 'Block number', 'Previous choice')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'prev_eff_glm_table.tex'))

# ----------------------------------- Previous effort, separated by environment ---------------------- #
d.accept.rate.effHist <- d %>% group_by(subjectNumber, effortHistory, blockType) %>% summarise(acceptRate = mean(response))

# Combine blockType and effortLevel into a single factor for grouping on the x-axis
d.accept.rate.effHist$grouping <- as.factor(interaction(d.accept.rate.effHist$blockType, d.accept.rate.effHist$effortHistory, sep = " - "))

image <- ggplot2::ggplot(d.accept.rate.effHist, aes(x = grouping, y = acceptRate, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,blockType)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,blockType), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) +
  labs(x = "effort offer (t-1)", y = "pr(accept)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image
# --------------------------------------------- reward model ----------------------------------- ##
load(file = paste0('glmm_output/glm_model_reward_', model_number, task_version, '.RData'))

tmp <- tidy(reward_model, conf.int = T, exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Trial number in block', 'Block number', 'Previous choice', 'Average reward', 'Previous reward', 'Effort offer (mid - low)', 'Effort offer (high - mid)', 'Low effort: hard - easy', 'Mid effort: hard - easy', 'High effort: hard - easy')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'reward_glm_table.tex'))

# --------------------------------------------- average effort model ----------------------------------- ##
load(file = paste0('glmm_output/glm_model_avg_effort_', model_number, task_version, '.RData'))

tmp <- tidy(avg_eff_model, conf.int = T, exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Environment', 'Background effort rate','Trial number in block', 'Response history', 'Block number','Environment:Background effort rate')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'prev_avg_effort_glm_table.tex'))
# ADDITIONAL PLOTS 
#----------------------------------------------------- EXERTED EFFORT (t-1) ---------------------------------------------------# 
d.accept.rate.exertHist <- d %>% group_by(subjectNumber, exertedEffortHistory) %>% summarise(acceptRate = mean(response))

image <- ggplot2::ggplot(d.accept.rate.exertHist, aes(x = exertedEffortHistory, y = acceptRate)) +
  geom_path(aes(group = subjectNumber), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = subjectNumber), position = pd, shape = 21, size = figure$subj_point_size, fill = figure$colour_subj_effort, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size, colour = figure$colour_effort) +
  stat_summary(aes(y = acceptRate, group = 1), fun.y = "mean", geom = "line", colour = figure$colour_effort) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  labs(x = "exerted effort (t-1)", y = "pr(accept)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )

# load and extract p-values from glm object
load(file = paste0('glmm_output/glm_model_exert_eff_', model_number, task_version, '.RData'))

p_values <- summary(exert_eff_model)$coefficients$cond[c("exertHist2_1", 'exertHist3_2', 'exertHist4_3'), "Pr(>|z|)"]
sig <- array(NA,c(5,length(p_values)))

for (c in 1:ncol(sig)) {
  if (p_values[c] < .001)
  {sig[1,c] <- "< .001"
  } else if (p_values[c] >= .05) 	{sig[1,c] <- "ns."
  } else if (p_values[c] < .05 & p_values[c] >= .001)	{sig[1,c] <- as.character(round(p_values[c],3))}
}

sig[2,] <- c(1.05, 1.05,1.05)
sig[3,] <- c(1, 2.1, 3.1)
sig[4,] <- c(1.9, 2.9,4)
sig[5,] <- c(0.0, 0.0,0.0)

for (c in 1:ncol(sig)){
  image <- image + geom_signif(annotation = sig[1,c], y_position = as.numeric(sig[2,c]),
                                                                           xmin = as.numeric(sig[3,c]), xmax = as.numeric(sig[4,c]),
                                                                           tip_length = as.numeric(sig[5,c]),
                                                                           colour = 'black', textsize = figure$p_label_size)}

if (model_number != ''){
  image <- image +
    scale_y_continuous(name = "pr(accept)<br><span style='font-size:8pt; font-style:italic;'>simulated</span>") +
    theme(axis.title.y=element_markdown(size = figure$font_size))
}
image
ggsave(file = paste0('plots/', task_version, '/', model_number,'accept_rate_exert_history.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

tmp <- tidy(exert_eff_model, conf.int = T, exponentiate = T, effects = 'fixed')
tmp <- tmp[,c(3, 4, 8, 9, 6, 7)]
colnames(tmp) <- c('Predictor', 'OR', 'CI low', 'CI high', 'z', 'p')
tmp[,c(6)] <- format.pval(tmp[,c(6)],2)
tmp[,c(1)] <- c('(Intercept)','Environment', 'Previous exerted (low-wait)', 'Previous exerted (mid-low)','Previous exerted (high-mid)','Environment:Previous exerted (low-wait)', 'Environment:Previous exerted (mid-low)','Environment:Previous exerted (high-mid)','Trial number in block', 'Block number')
latex <- xtable(tmp, type = 'latex', digits = c(1, NaN, 2, 2, 2, 2, -2))
print(latex, include.rownames = FALSE, file = paste0('glmm_output/',task_version, '_', model_number, 'prev_exert_glm_table.tex'))
# ADDITIONAL PLOTS 

## ------------------------------------- EFFORT SEEN BUT NOT EXERTED plots -------------------------------##

d <- d %>% group_by()
d.accept.rate.effHist <- d %>% filter(responseHistory == 'wait') %>%
  group_by(subjectNumber, blockType, effortHistory) %>% 
  summarise(acceptRate = mean(response))

# Combine blockType and effortHistory into a single factor for grouping on the x-axis
d.accept.rate.effHist$grouping <- as.factor(interaction(d.accept.rate.effHist$blockType, d.accept.rate.effHist$effortHistory, sep = " - "))

image <- ggplot2::ggplot(d.accept.rate.effHist, aes(x = grouping, y = acceptRate, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,effortHistory)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,effortHistory), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  stat_summary(aes(y = acceptRate, group = blockType), fun.y = "mean", geom = "line") +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) +
  labs(x = "effort offer (t-1)", y = "pr(accept)") +
  theme_classic() +
  
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image
ggsave(file = paste0('plots/', task_version, '/', model_number, 'accept_rate_eff_not_exerted.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")



##--------------------------- Reward plots ----------------------- 
d.reward <- d %>% 
  group_by(subjectNumber, blockType) %>% 
  summarise(rewardTotal = sum(reward))

image <- ggplot2::ggplot(d.reward, aes(x = blockType, y= rewardTotal, colour = blockType)) + 
  geom_path(aes(group = subjectNumber), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = subjectNumber, fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  
  labs(x = "environment", y = "credits earned") +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image
ggsave(file = paste0('plots/', task_version,'/total_reward_earned.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")


# Reward history plot 
d.reward.history <- d %>% 
  group_by(subjectNumber, rewardHistory) %>%
  summarise(acceptRate = mean(response))

image <- ggplot2::ggplot(d.reward.history, aes(x = rewardHistory, y= acceptRate)) + 
  geom_path(aes(group = subjectNumber), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = subjectNumber), position = pd, shape = 21, size = figure$subj_point_size, fill = figure$colour_subj_reward, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size, colour = figure$colour_reward) +
  stat_summary(aes(y = acceptRate), fun.y = "mean", geom = "line", colour = figure$colour_reward) +
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +  labs(x = "reward (t-1)", y = "pr(accept)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image
ggsave(file = paste0('plots/', task_version,'/reward_history.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# ------------------- check that averageRewardRate was not different in hard vs easy environments ------------------#
image <- ggplot(d, aes(x = averageRewardRate, y = response, colour = blockType)) + 
  geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial')) + 
  scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.25), limits = c(0, 1)) + 
  scale_x_continuous(name = "averageRewardRate.") + 
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image
ggsave(file = paste0('plots/', task_version, '/', model_number, 'avg_reward_env.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# averageRewardRate has same effect on behaviour in both environments: as averageRewardRate increases, participants were more likely to accept next offer (opposite of opp cost hypothesis)

# ----------------------------- Average effort rate ------------------------------#

image <- ggplot(d, aes(x = averageEffortRate, y = response, colour = blockType)) + 
  geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial')) + 
  scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.25), limits = c(0, 1)) + 
  scale_x_continuous(name = "Background effort rate") + 
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image
ggsave(file = paste0('plots/', task_version, '/', model_number, 'avg_eff_env.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# ----------------------------- Average exerted effort rate ------------------------------#

# image <- ggplot(d, aes(x = averageExertedRate, y = response)) + 
#   geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial'), colour = figure$colour_effort, linewidth = 0.5) + 
#   scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.25), limits = c(0, 1)) + 
#   scale_x_continuous(name = "Background exerted rate") + 
#   theme_classic() + 
#   theme(
#     legend.title = element_blank(), 
#     legend.position = "none",
#     text = element_text(size = figure$font_size))
# image
# ggsave(file = paste0('plots/', task_version, '/', model_number, 'avg_exert.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

image <- ggplot(d, aes(x = averageExertedRate, y = response, colour = blockType)) + 
  geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial')) + 
  scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.25), limits = c(0, 1)) + 
  scale_x_continuous(name = "Average exerted effort") + 
  scale_fill_manual(values = c(pal_npg("nrc")(2)[2],pal_npg("nrc")(1)[1])) + 
  scale_colour_manual(values = c(pal_npg("nrc")(2)[2],pal_npg("nrc")(1)[1])) + 
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image
ggsave(file = paste0('plots/', task_version, '/', model_number, 'avg_exert_env.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# 
# image <- ggplot(d, aes(x = averageEffortRate, y = averageExertedRate)) +
#   geom_point() +
#   scale_y_continuous(name = "Average exert rate") +
#   scale_x_continuous(name = "Average effort rate") +
#   geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) +
#   theme_classic() +
#   stat_cor(method = 'spearman', p.digits = 2, size = 2, label.y = 1) +
#   theme(
#     legend.title = element_blank(),
#     legend.position = "none",
#     text = element_text(size = figure$font_size))
# image

# ---------------------------- Trial N in block -------------------------------------# 
#How does acceptance rate for mid level option change over trial number, in easy vs hard environments? 

d.mid <- d %>% filter(effortLevel == 'mid')

image <- ggplot(d.mid, aes(x = trialNinBlock, y = response, colour = blockType)) + 
  geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial'), linewidth = 0.5) + 
  scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.2)) + 
  scale_x_continuous(name = "trial") + 
  coord_cartesian(ylim = c(0, 1.2)) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image

ggsave(file = paste0('plots/', task_version,'/trial_n_mid_effort.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# d.high <- d %>% filter(effortLevel == 'high')
# 
# image <- ggplot(d.high, aes(x = trialNinBlock, y = response, colour = blockType)) + 
#   geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial'), linewidth = 0.5) + 
#   scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.2)) + 
#   scale_x_continuous(name = "trial") + 
#   coord_cartesian(ylim = c(0, 1.2)) +
#   scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
#   theme_classic() + 
#   theme(
#     legend.title = element_blank(), 
#     legend.position = "none",
#     text = element_text(size = figure$font_size))
# image
# 
# 
# d.low <- d %>% filter(effortLevel == 'low')
# 
# image <- ggplot(d.low, aes(x = trialNinBlock, y = response, colour = blockType)) + 
#   geom_smooth(method = "glm", formula = 'y~x', method.args = list('binomial'), linewidth = 0.5) + 
#   scale_y_continuous(name = "pr(accept)", breaks = seq(0,1,0.2)) + 
#   scale_x_continuous(name = "trial") + 
#   coord_cartesian(ylim = c(0, 1.2)) +
#   scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
#   theme_classic() + 
#   theme(
#     legend.title = element_blank(), 
#     legend.position = "none",
#     text = element_text(size = figure$font_size))
# image


# ---------------------------- FORCE EXERTED PLOTS ---------------------#
d.force.exerted <- d %>% group_by(subjectNumber, blockType, effortLevel) %>% 
  filter(response == 1 & timeInWindow >= 1) %>% 
  summarise(forceExerted = mean(forceData, na.rm = T))

# Combine blockType and effortLevel into a single factor for grouping on the x-axis
d.force.exerted$grouping <- as.factor(interaction(d.force.exerted$blockType, d.force.exerted$effortLevel, sep = " - "))

image <- ggplot2::ggplot(d.force.exerted, aes(x = grouping, y = forceExerted, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,effortLevel)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,effortLevel), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) + 
  labs(x = "effort", y = "force exerted (normalised AUC)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image
ggsave(file = paste0('plots/', task_version, '/', 'force_exerted', '.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# -------------------------------- REACTION TIMES -----------------------------#
d.RT <- d %>% group_by(subjectNumber, blockType, effortLevel) %>% summarise(RT = mean(RT))

# Combine blockType and effortLevel into a single factor for grouping on the x-axis
d.RT$grouping <- as.factor(interaction(d.RT$blockType, d.RT$effortLevel, sep = " - "))

image <- ggplot2::ggplot(d.RT, aes(x = grouping, y = RT, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,effortLevel)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,effortLevel), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) + 
  labs(x = "effort", y = "decision time (s)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(), 
    legend.position = "none",
    text = element_text(size = figure$font_size))
image
ggsave(file = paste0('plots/', task_version, '/', 'decision_time', '.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")

# --------------------------------- RTs as function of previous effort ---------------------------#
d.RT.effHist <- d %>% group_by(subjectNumber, blockType, effortHistory) %>% summarise(RT = mean(RT))

# Combine blockType and effortLevel into a single factor for grouping on the x-axis
d.RT.effHist$grouping <- as.factor(interaction(d.RT.effHist$blockType, d.RT.effHist$effortHistory, sep = " - "))

image <- ggplot2::ggplot(d.RT.effHist, aes(x = grouping, y = RT, colour = blockType)) +
  geom_path(aes(group = interaction(subjectNumber,effortHistory)), position = pd, colour = 'grey', alpha = figure$alpha, linewidth = figure$line_width) +
  geom_point(aes(group = interaction(subjectNumber,effortHistory), fill = blockType), position = pd, shape = 21, size = figure$subj_point_size, colour = 'white', stroke = 0.3) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", size = figure$mean_point_size) +
  scale_colour_manual(values = c(figure$colour_easy, figure$colour_hard)) +
  scale_fill_manual(values = c(figure$colour_subj_easy, figure$colour_subj_hard)) +
  scale_x_discrete(labels = c('', 'low', '', 'mid', '', 'high')) +
  labs(x = "effort offer (t-1)", y = "decision time (s)") +
  theme_classic() + 
  theme(
    legend.title = element_blank(),
    legend.position = "none",
    text = element_text(size = figure$font_size)
  )
image

ggsave(file = paste0('plots/', task_version, '/', model_number, 'RT_eff_history_env.pdf'), plot = image, width = figure$width, height = figure$height, unit = 'cm', device = "pdf", bg = "transparent")


#############################################################################################################
## -------------------------------------- Bayes factors for GLMs ------------------------------------------- ##

# Compare larger vs smaller model to get (null) Bayes factor for previous expected value
# Using BIC equation (Wagenmakers, 2007): BF01 = exp((BIClarger - BICsmaller) / 2)
reward_BF_01 <- exp((BIC(reward_model) - BIC(main_model)) / 2)

# -------------------------- Model parameter correlations with behaviour ------------------------- # 
model_params <- read.csv(paste('../data/fit/',task_version,'/fit_params_M2.csv', sep = ""))

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

# Discount parameter
image <- ggplot(d.accept.rate.params, aes(x = kOffer, y = opp_cost)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('discount: ') + ylab('pr(accept): hard - easy') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'pearson', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image

# for alpha, do logarithm or spearmans since so skewed
image <- ggplot(d.accept.rate.params, aes(x = alpha, y = opp_cost)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('learning rate - spearmans') + ylab('pr(accept): hard - easy') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'spearman', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image

image <- ggplot(d.accept.rate.params, aes(x = log(alpha), y = opp_cost)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('log(learning rate)') + ylab('pr(accept): hard - easy') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'pearson', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image

# softmax temperature
image <- ggplot(d.accept.rate.params, aes(x = beta, y = opp_cost)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('softmax temperature') + ylab('pr(accept): hard - easy') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'pearson', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image

# weight
image <- ggplot(d.accept.rate.params, aes(x = weight, y = opp_cost)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('weight') + ylab('pr(accept): hard - easy') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'pearson', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image


# Discount parameter x weight
image <- ggplot(d.accept.rate.params, aes(x = kOffer, y = weight)) + 
  geom_hline(yintercept = 0, linetype = 'dashed', linewidth = 0.2) +
  geom_point(shape = 21, fill = figure$colour_model, colour = 'white', size = 1, stroke = 0.1) + 
  xlab('discount: ') + ylab('weight') + 
  geom_smooth(method='lm', formula= y~x, colour = figure$colour_model, linewidth = 0.4) + 
  theme_classic() + 
  stat_cor(method = 'pearson', p.digits = 2, size = 2, label.y = 1) + 
  theme(text = element_text(size = 8))
image
#ggsave(file = paste0('plots/', task_version, '/', 'k_opp_cost_correlation', '.pdf'), plot = image, width = 4, height = 4, unit = 'cm', device = "pdf", bg = "transparent")


