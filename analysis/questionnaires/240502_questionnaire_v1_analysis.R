## Quick look at questionnaire measures - AMI - AET v1 
# Emma Scholey
# 2 May 2024 


# Read in data and clean
################ SETUP ################ 
rm(list = ls(all = TRUE)) # clear environment

# load packages
library(tidyverse)
library(MASS)
library(lme4)
library(optimx)
library(sjPlot)    # to visualizing mixed-effects models
library(ggpubr)
library(ggsci)

setwd('~/Dropbox/average-effort/code/analysis/') # adjust as required

# select the data you want to analyse
filename = 'behav_summary_v1.csv' # behavioural study v1

#read data
d <- read.csv(paste('../../data_derived/v1/',filename, sep = ""))

d <- d %>% filter(subjectNumber != 6) 

#------------------------- clean data -------------------------- <- <- #

d.subject_acceptAll_exclude <- d %>% group_by(subjectNumber) %>% filter(response != 8888) %>% summarise(M = mean(response)) %>% filter(M > 0.95)
d <- filter(d, !(subjectNumber %in% d.subject_acceptAll_exclude$subjectNumber))

# look at trials where they accepted but didn't reach the threshold
failed_accepted <- d %>% mutate(failed = timeInWindow < 1) %>% group_by(subjectNumber) %>% summarise(failed = mean(failed, na.rm = T))
excludeFailed <- failed_accepted %>% filter(failed > 0.2) 
# this threshold (0.2) based on exceeding Q3 + 1.5 * IQR - since data is heavily skewed e.g. see boxplot below 
# boxplot(failed_accepted$failed)
d <- filter(d, !(subjectNumber %in% excludeFailed$subjectNumber))

missed_many <- d %>% group_by(subjectNumber) %>% summarise(missed = mean(response == 8888))
excludeMissed <- missed_many %>% filter(missed > 0.1) 
d <- filter(d, !(subjectNumber %in% excludeMissed$subjectNumber))

# remove missed trials 
d <- d %>% filter(response != 8888)

# prep data for plotting 
d$effortLevel <- as.factor(d$effortLevel)  
d$blockType <- as.factor(d$blockType)

#------------------------- read questionnaire data -------------------------- <- <- #
#read data
q <- readxl::read_xlsx('../../data_raw/v1/AET_questionnaire_results_v1.xlsx')

#q <- readxl::read_xlsx('../../data_raw/v3_nolearning/questionnaire_data_v3.xlsx')

q <- q[, c(2:4, 8:25, 27:46, 48:61)]

colnames(q) <- c('subjectNumber', 'Age', 'Gender',
                 'AMI_1',	'AMI_2',	'AMI_3',	'AMI_4',	'AMI_5',	'AMI_6',	'AMI_7',	'AMI_8',	'AMI_9',	'AMI_10',	'AMI_11',	'AMI_12',	'AMI_13',	'AMI_14',	'AMI_15',	'AMI_16',	'AMI_17',	'AMI_18',	
                 'MFI_1',	'MFI_2',	'MFI_3',	'MFI_4',	'MFI_5',	'MFI_6',	'MFI_7',	'MFI_8',	'MFI_9',	'MFI_10',	'MFI_11',	'MFI_12',	'MFI_13',	'MFI_14',	'MFI_15',	'MFI_16',	'MFI_17',	'MFI_18',	'MFI_19',	'MFI_20',	
                 'SHAPS_1',	'SHAPS_2',	'SHAPS_3',	'SHAPS_4',	'SHAPS_5',	'SHAPS_6',	'SHAPS_7',	'SHAPS_8',	'SHAPS_9',	'SHAPS_10',	'SHAPS_11',	'SHAPS_12',	'SHAPS_13',	'SHAPS_14')

q$subjectNumber[q$subjectNumber == 97759] <- 122

# tidy up subject number to be consistent with behavioural data
q$subjectNumber <- as.numeric(q$subjectNumber) - 100

# do exclusions 
q <- filter(q, !(subjectNumber %in% d.subject_acceptAll_exclude$subjectNumber))
q <- filter(q, !(subjectNumber %in% excludeFailed$subjectNumber))
q <- filter(q, !(subjectNumber %in% excludeMissed$subjectNumber))
q <- filter(q, !subjectNumber == 6) # remove 6 too as data incomplete - only for v1
#q <- filter(q, !subjectNumber < 17) # remove first 16 participants for v3 - wrong MVC. 
q <- q [order(q$subjectNumber),]

d <- filter(d, subjectNumber %in% q$subjectNumber) # make sure we have the same subjects in each - only needed for v3, since not everyone did the questionnaires

# ------------------------ calculate acceptance rates and opp cost effect ----------------------- #
d.opp.cost <- d %>% 
  group_by(subjectNumber, blockType, effortLevel) %>% 
  summarise(acceptRate = mean(response)) %>% 
  filter(effortLevel == 0.4) %>% ungroup() %>%
  reframe(meanDiffMid = acceptRate[blockType == 99] - acceptRate[blockType == 11])

d.accept.rate <- d %>% group_by(subjectNumber) %>% summarise(acceptRate = mean(response))
d.accept.rate.high <- d %>% group_by(subjectNumber) %>% filter(effortLevel == 0.6) %>% summarise(acceptRate = mean(response))


# ---------- recode AMI ------------------- #
#Selecting the columns for AMI
AMI <- q %>%
  dplyr::select(AMI_1:AMI_18)
#Recoding the participant responses (All the items are reverse scored)
recode_AMI <- c("Completely UNTRUE" = 4, "Mostly untrue" = 3, "Neither true nor untrue" = 2, "Quite true" = 1, "Completely TRUE" = 0) 
q <- q %>%
  mutate(across(starts_with("AMI_"), ~ifelse(. %in% names(recode_AMI), recode_AMI[.], .))) %>%
  mutate(across(starts_with("AMI_"), as.numeric))

#AMI Subscale total scores
#Emotional sensitivity (ES)
AMI_ES <- c("AMI_1", "AMI_6", "AMI_7", "AMI_13", "AMI_16", "AMI_18")
q <- q %>%
  mutate(AMI_ES_sum = rowMeans(dplyr::select(., all_of(AMI_ES)), na.rm = TRUE)) #Creating a new column with sum of scores for the ES subscale

#Social motivation (SM)
AMI_SM <- c("AMI_2", "AMI_3", "AMI_4", "AMI_8", "AMI_14", "AMI_17")
q <- q %>%
  mutate(AMI_SM_sum = rowMeans(dplyr::select(., all_of(AMI_SM)), na.rm = TRUE)) #Creating a new column with sum of scores for the SM subscale

#Behavioural activation (BA)
AMI_BA <- c("AMI_5", "AMI_9", "AMI_10", "AMI_11", "AMI_12", "AMI_15")
q <- q %>%
  mutate(AMI_BA_sum = rowMeans(dplyr::select(., all_of(AMI_BA)), na.rm = TRUE)) #Creating a new column with sum of scores for the BA subscale

#Total- full scale
q <- q %>%
  mutate(AMI_sum = rowMeans(dplyr::select(.,AMI_1:AMI_18), na.rm = TRUE))

# ---------------------------------- plot correlations ---------------------------- #
# Don't need to join by subjectNumber, since we have re-ordered both, so in same order 
# Look at overall acceptance rates
q.accept.rate <- cbind(d.opp.cost$meanDiffMid, q$AMI_sum,q$AMI_ES_sum,q$AMI_SM_sum,q$AMI_BA_sum)
q.accept.rate <- as.data.frame(q.accept.rate)

colnames(q.accept.rate) <- c('Opportunity_cost_effect', 'AMI_Total', 'AMI_ES', 'AMI_SM', 'AMI_BA')

corr_matrix <- cor(q.accept.rate)

library(psych) 
cor_test <- corr.test(q.accept.rate)$p

library(corrplot)  
corrplot(
  corr_matrix,
  p.mat = cor_test,
  sig.level = 0.05,
  insig = "blank",  
  type = "lower",     # Display lower triangle of the matrix
  tl.col = "black",     # Color of variable names
  tl.cex = 1          # Adjust the font size of variable names
)

# just AMI emotional sensitivity and opportunity cost effect 

ggplot(q.accept.rate, aes(x = Opportunity_cost_effect, y = AMI_ES)) + geom_point(colour = 'mediumpurple4') + 
  xlab('Opportunity cost effect') + ylab('AMI: Emotional Sensitivity score') + 
  ylim(c(0,5)) +
  geom_smooth(method='lm', formula= y~x) + 
  theme_minimal() +
  theme(text = element_text(size = 18))

# Look at size of opportunity cost effect 

## ------------------ correlate with model parameters -------------------------- ##
filename = 'minNLLFitParams_M14.csv' 

#read data
m <- read.csv(paste('../../data_derived/v1/fitting/',filename, sep = ""))

m <- cbind(m,q$AMI_sum,q$AMI_ES_sum,q$AMI_SM_sum,q$AMI_BA_sum, q.accept.rate$Opportunity_cost_effect)

colnames(m) <- c('k', 'beta', 'alpha', 'fatigue', 'AMI_Total', 'AMI_ES', 'AMI_SM', 'AMI_BA', 'opp_cost_effect')

corr_matrix <- cor(m)

library(psych) 
cor_test <- corr.test(m, method = 'spearman')$p

library(corrplot)  
corrplot(
  corr_matrix,
  p.mat = cor_test,
  sig.level = 0.05,
  insig = "blank",  
  type = "lower",     # Display lower triangle of the matrix
  tl.col = "black",     # Color of variable names
  tl.cex = 1          # Adjust the font size of variable names
)

ggplot(m, aes(x = fatigue, y = opp_cost_effect)) + geom_point(colour = 'mediumpurple4') + 
  xlab('Fatigue') + ylab('Opp cost effect') + 
  geom_smooth(method='lm', formula= y~x) + 
  theme_minimal() +
  theme(text = element_text(size = 18))


