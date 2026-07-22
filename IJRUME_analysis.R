#(Mike 7/22/26) LEGACY SCRIPT -- kept as the historical record of the analysis
#behind:
#  - Roberge et al., "Calculus Cognitive Diagnostic: Mathematics skills
#    tested in first semester calculus courses" (PERC 2025;
#    Articles/PERC2025_Roberge.pdf)
#  - Roberge et al., "Moving Beyond Total Scores with Skill-Proficiency
#    Profiles on Concept Inventories" (RUME conference proceedings;
#    Articles/RUME 2025 CCD-UNMASKED-PRESUBMISSION.pdf)
#
#As received, this script could not run to completion: Qmatrix.xlsx was
#missing from the repo, and the CCA/CCI cognitive-diagnostic section had
#several bugs that stopped execution before any DINA model was fit. The
#following were fixed here -- the minimum needed to run and reproduce the
#conference results, nothing else:
#  1. Q_pca was read from "../IRT/Qmatrix.xlsx", a path that doesn't exist in
#     this repo -- changed to "Qmatrix.xlsx".
#  2. Qmatrix.xlsx itself was missing. It has been reconstructed from
#     Qmatrices/CCD-second coding.xlsx (the "5LO" Qval-updated coding) and
#     verified item-for-item against Table IV of the PERC2025 manuscript --
#     see the README sheet in Qmatrix.xlsx for the derivation.
#  3. cca_pre/cca_post were bound to single-column score summaries earlier in
#     this script (for the descriptive-stats section) and were never rebuilt
#     into item-level response matrices before being handed to GDINA here --
#     added code to rebuild them from cca_binary.
#  4. cci_pre_binary/cci_post_binary were referenced but never defined
#     anywhere in the script -- added code to build them from cci_clean.
#  5. Typo: personparm(cre_pca_dina, ...) -- fixed to pre_cca_dina.
#  6. Typo: !pre_missing_idx / !post_missing_idx -- fixed to
#     !pre_missing_idx_pca / !post_missing_idx_pca.
#
#With those fixes, this script's DINA/GDINA fit statistics (RMSEA, SRMSR)
#reproduce the published Table V values closely for all three instruments.
#
#One known bug remains UNFIXED here (see the inline notes near each
#instrument's Sankey/profile section below): GDINA drops respondents with
#<=1 valid item response, and this script never re-aligns the shortened
#output back to the full sample before combining pre/post skill profiles.
#That silently corrupts PCA's profile labels and crashes CCA/CCI's
#bind_cols() call, so the Sankey diagrams cannot currently be produced by
#this script.
#
#IJRUME_analysis.Rmd is the corrected, go-forward version for the IJRUME
#manuscript -- it fixes all of the above, including the remaining Sankey
#bug. Run this file only when you need to exactly reproduce the PERC2025 /
#RUME conference-proceedings analysis as originally run.

library(dplyr)
library(tidyr)
library(readxl)
library(writexl)
library(ggplot2)
library(mirt)
library(GDINA)
library(networkD3)
library(patchwork)
library(htmlwidgets)
library(webshot2)   # works without PhantomJS
library(cowplot)
library(magick)
library(lmerTest)
library(stringr)
library(tibble)
library(VIM)


set.seed(1234)

#need to import the prepared CCI, CCA and PCA datasets
#datascript.R is the file used to prepare this data.
#build some stuff for descriptive and then move on below

#load data
#The CCI and CCA data is combine v1 and v2
cci_data <- read.csv("cci_data_v12.csv")
cca_data <- read.csv("cca_data_v12.csv")
pca_data <- read.csv("pca_data.csv")


################################
#                              #
#  Descriptive Statistics/vizs #
#                              #
################################

#
#prepare CCI data:
#
cci_courses <- cci_data %>% count(course_id)
write.csv(cci_courses, "cci_courses.csv")
cci_inst <-  cci_data %>% count(instructor) 
write.csv(cci_inst, "cci_inst.csv")
cci_sex <- cci_data %>% group_by(male, female) %>% summarize(n=n())


cci_pre <- cci_data %>% select(pre_score) %>% rename(score = pre_score)
cci_pre$version <- "pre"
cci_post <- cci_data %>% select(post_score) %>% rename(score = post_score)
cci_post$version <- "post"

#I must use this for descriptive stats?
cci_scores <- rbind(cci_pre, cci_post)

#
#prepare CCA data: 
#
cca_courses <- cca_data %>% count(course_id)
write.csv(cca_courses, "cca_courses.csv")
cca_inst <-  cca_data %>% count(instructor) 
write.csv(cca_inst, "cca_inst.csv")
cca_sex <- cca_data %>% group_by(male, female) %>% summarize(n=n())

cca_pre <- cca_data %>% select(pre_score) %>% rename(score = pre_score)
cca_pre$version <- "pre"
cca_post <- cca_data %>% select(post_score) %>% rename(score = post_score)
cca_post$version <- "post"

cca_scores <- rbind(cca_pre, cca_post)

#
#prepare PCA data:
#
pca_courses <- pca_data %>% count(course_id)
write.csv(pca_courses, "pca_courses.csv")
pca_sex <- pca_data %>% group_by(male, female) %>% summarize(n=n())


pca_pre <- pca_data %>% select(pre_score) %>% rename(score = pre_score)
pca_pre$version = "pre"
pca_post <- pca_data %>% select(post_score) %>% rename(score = post_score)
pca_post$version = "post"

pca_scores <- rbind(pca_pre, pca_post) 


#let's add a column that can be used to make a density plot of gains by instrument.
cci_data <- cci_data %>% mutate(gains = post_score - pre_score, version = "CCI")
cca_data <- cca_data %>% mutate(gains = post_score - pre_score, version = "CCA")
pca_data <- pca_data %>% mutate(gains = post_score - pre_score, version = "PCA")

cci_gains <- cci_data %>% select(gains, version)
cca_gains <- cca_data %>% select(gains, version)
pca_gains <- pca_data %>% select(gains, version)
gains <- rbind(pca_gains, cci_gains, cca_gains)




#xlim_all <- range(c(pca_theta$theta, cci_theta$theta), na.rm = TRUE)

#density plots by score
cci_score_density <- ggplot(cci_scores, aes(x = score, fill=version)) + 
  geom_density(na.rm=TRUE, alpha = 0.3, color = "black") + 
  labs(title="CCI: Pre-test and post-test scores") + 
  theme_minimal(base_size = 12) +  
  theme(legend.position="bottom", plot.title = element_text(hjust = 0.5))

cca_score_density <- ggplot(cca_scores, aes(x = score, fill=version)) + 
  geom_density(na.rm=TRUE, alpha = 0.3, color = "black") + 
  labs(title="CCA: Pre-test and post-test scores") + 
  theme_minimal(base_size = 12) +  
  theme(legend.position="bottom", plot.title = element_text(hjust = 0.5))


pca_score_density <- ggplot(pca_scores, aes(x = score, fill=version)) + 
  geom_density(na.rm=TRUE, alpha = 0.3, color = "black") + 
  labs(title="PCA: Pre-test and post-test scores") + 
  theme_minimal(base_size = 12) +  
  theme(legend.position="bottom", plot.title = element_text(hjust = 0.5))


cci_score_density + cca_score_density + pca_score_density


#density plot by gain

gains_plot <- ggplot(gains, aes(x = gains, fill=version)) + 
  geom_density(na.rm=TRUE, alpha = 0.3, color = "black") + 
  labs(title="Pre/Post gains by assessment") + 
  theme_minimal(base_size = 12) +  
  theme(legend.position="bottom", plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = 0, color = "black", linetype = "dotted", linewidth = 1)
gains_plot

#summary statistics
summary_scores_cci <- cci_scores %>%
  group_by(version) %>%
  summarise(
    mean_score   = mean(score, na.rm = TRUE),
    median_score = median(score, na.rm = TRUE),
    sd_score     = sd(score, na.rm = TRUE),
    n            = n()   # optional: count of rows
  )

summary_scores_cca <- cca_scores %>%
  group_by(version) %>%
  summarise(
    mean_score   = mean(score, na.rm = TRUE),
    median_score = median(score, na.rm = TRUE),
    sd_score     = sd(score, na.rm = TRUE),
    n            = n()   # optional: count of rows
  )

summary_scores_pca <- pca_scores %>%
  group_by(version) %>%
  summarise(
    mean_score   = mean(score, na.rm = TRUE),
    median_score = median(score, na.rm = TRUE),
    sd_score     = sd(score, na.rm = TRUE),
    n            = n()   # optional: count of rows
  )




#Exploring Course Level variation

#CCI
course_means_cci <- cci_data %>%
  group_by(course_id) %>%
  summarise(
    mean_pre  = mean(pre_score,  na.rm = TRUE),
    mean_post = mean(post_score, na.rm = TRUE),
    sd_pre    = sd(pre_score, na.rm = TRUE),
    sd_post   = sd(post_score, na.rm = TRUE),
    n_pre  = sum(!is.na(pre_score)),
    n_post = sum(!is.na(post_score)),
    .groups = "drop"
  )

course_means_cci <- course_means_cci %>% mutate(gain = round(mean_post - mean_pre, 2),
                                        normgain = round((mean_post - mean_pre)/(100 - mean_pre),3),
                                        cohensD = round((mean_post - mean_pre)/(sqrt(0.5*(sd_pre^2 + sd_post^2))),3))
hist(course_means_cci$cohensD)
write.csv(course_means_cci, "course_means_cci.csv")

#CCA
course_means_cca <- cca_data %>%
  group_by(course_id) %>%
  summarise(
    mean_pre  = mean(pre_score,  na.rm = TRUE),
    mean_post = mean(post_score, na.rm = TRUE),
    sd_pre    = sd(pre_score, na.rm = TRUE),
    sd_post   = sd(post_score, na.rm = TRUE),
    n_pre  = sum(!is.na(pre_score)),
    n_post = sum(!is.na(post_score)),
    .groups = "drop"
  )

course_means_cca <- course_means_cca %>% mutate(gain = round(mean_post - mean_pre, 2), 
                                                normgain = round((mean_post - mean_pre)/(100 - mean_pre),3),
                                            cohensD = round((mean_post - mean_pre)/(sqrt(0.5*(sd_pre^2 + sd_post^2))),3))

hist(course_means_cca$cohensD)
write.csv(course_means_cca, "course_means_cca.csv")

#PCA
course_means_pca <- pca_data %>%
  group_by(course_id) %>%
  summarise(
    mean_pre  = mean(pre_score,  na.rm = TRUE),
    mean_post = mean(post_score, na.rm = TRUE),
    sd_pre    = sd(pre_score, na.rm = TRUE),
    sd_post   = sd(post_score, na.rm = TRUE),
    n_pre  = sum(!is.na(pre_score)),
    n_post = sum(!is.na(post_score)),
    .groups = "drop"
  )

course_means_pca <- course_means_pca %>% mutate(gain = round(mean_post - mean_pre, 2), 
                                                normgain = round((mean_post - mean_pre)/(100 - mean_pre),3),
                                                cohensD = round((mean_post - mean_pre)/(sqrt(0.5*(sd_pre^2 + sd_post^2))),3))

hist(course_means_pca$cohensD)
write.csv(course_means_pca, "course_means_pca.csv")



################################
#                              #
#         HLM                  #
#                              #
################################
set.seed(1234)


#take only the columns we need for this
cci_hlm_prep <- cci_data %>% select(student_id, course_id, pre_score, post_score)

#pivot longer so we can model score based on version while
#accounting for course level variation
#filter out NAs for score either because of missing information or filter effects
#during data preparation
cci_hlm <- cci_hlm_prep %>% pivot_longer(
  cols = c(pre_score, post_score),
  names_to = "version",
  values_to = "score") %>%
  mutate(version = if_else(version=="pre_score", 0, 1)) %>% filter(!is.na(score))

#null model (to compute ICC)
cci_hlm_model_null <- lmer(score ~ (1|student_id) + (1|course_id), data = cci_hlm, REML=TRUE)
summary(cci_hlm_model_null)

VarCorr(cci_hlm_model_null)
cci_null_var <- as.data.frame(VarCorr(cci_hlm_model_null))
#results of VarCorr:
cci_student_sd <- cci_null_var[cci_null_var$grp=="student_id",]$sdcor #student_id
cci_course_sd <- cci_null_var[cci_null_var$grp=="course_id",]$sdcor #course_id  
cci_residual_sd <- cci_null_var[cci_null_var$grp =="Residual",]$sdcor #residual   

ICC_cci_student0 <- (cci_student_sd^2)/(cci_student_sd^2 + cci_course_sd^2 + cci_residual_sd^2)
ICC_cci_student0

ICC_cci_course0 <- (cci_course_sd^2)/(cci_student_sd^2 + cci_course_sd^2 + cci_residual_sd^2)
ICC_cci_course0

#note: here I'm using variance_of_interest/(sum of all the variances)
#this gives the same result as the icc() function from the performance library package
#student_id: 0.4332486 
#course_id: 0.04267927

#model 1: random intercepts fixed slope
cci_hlm_model <- lmer(score ~ version + (1|student_id) + (1|course_id), data=cci_hlm)
summary(cci_hlm_model)
#Intercept:      
#version:      


#model 2: random intercepts and random slopes
cci_hlm_model2 <- lmer(score ~ version + (1|student_id) + (1+version|course_id), data=cci_hlm)
summary(cci_hlm_model2)
#
#Intercept:
#version:
#

anova(cci_hlm_model2, cci_hlm_model)
  

######--CCA--#######

#take only the columns we need for this
cca_hlm_prep <- cca_data %>% select(student_id, course_id, pre_score, post_score)

#pivot longer so we can model score based on version while
#accounting for course level variation
cca_hlm <- cca_hlm_prep %>% pivot_longer(
  cols = c(pre_score, post_score),
  names_to = "version",
  values_to = "score") %>%
  mutate(version = if_else(version=="pre_score", 0, 1))

#null model (to compute ICC)
cca_hlm_model_null <- lmer(score ~ (1|student_id) + (1|course_id), data = cca_hlm)
summary(cca_hlm_model_null)

cca_null_var <- as.data.frame(VarCorr(cca_hlm_model_null))

cca_student_sd <- cca_null_var[cca_null_var$grp=="student_id",]$sdcor #student_id
cca_course_sd <- cca_null_var[cca_null_var$grp=="course_id",]$sdcor #course_id  
cca_residual_sd <- cca_null_var[cca_null_var$grp =="Residual",]$sdcor #residual   

ICC_cca_student0 <- (cca_student_sd^2)/(cca_student_sd^2 + cca_course_sd^2 + cca_residual_sd^2)
ICC_cca_student0

ICC_cca_course0 <- (cca_course_sd^2)/(cca_student_sd^2 + cca_course_sd^2 + cca_residual_sd^2)
ICC_cca_course0


cca_hlm_model <- lmer(score ~ version + (1|student_id) + (1|course_id), data=cca_hlm)
summary(cca_hlm_model)


#model 2: random intercepts and random slopes
cca_hlm_model2 <- lmer(score ~ version + (1|student_id) + (1+version|course_id), data=cca_hlm)
summary(cca_hlm_model2)
#
anova(cca_hlm_model, cca_hlm_model2)


#############--PCA--#############

pca_hlm_prep <- pca_data %>% select(student_id, course_id, pre_score, post_score)

#pivot longer so we can model score based on version while
#accounting for course level variation
pca_hlm <- pca_hlm_prep %>% pivot_longer(
  cols = c(pre_score, post_score),
  names_to = "version",
  values_to = "score") %>%
  mutate(version = if_else(version=="pre_score", 0, 1))

#null model (to compute ICC)
pca_hlm_model_null <- lmer(score ~ (1|student_id) + (1|course_id), data = pca_hlm)
summary(pca_hlm_model_null)

pca_null_var <- as.data.frame(VarCorr(pca_hlm_model_null))

pca_student_sd <- pca_null_var[pca_null_var$grp=="student_id",]$sdcor #student_id
pca_course_sd <- pca_null_var[pca_null_var$grp=="course_id",]$sdcor #course_id  
pca_residual_sd <- pca_null_var[pca_null_var$grp =="Residual",]$sdcor #residual   

ICC_pca_student0 <- (pca_student_sd^2)/(pca_student_sd^2 + pca_course_sd^2 + pca_residual_sd^2)
ICC_pca_student0

ICC_pca_course0 <- (pca_course_sd^2)/(pca_student_sd^2 + pca_course_sd^2 + pca_residual_sd^2)
ICC_pca_course0

pca_hlm_model <- lmer(score ~ version + (1|student_id) + (1|course_id), data=pca_hlm, REML=FALSE)
summary(pca_hlm_model)


pca_hlm_model2 <- lmer(score ~ version + (1|student_id) + (1 + version|course_id), data=pca_hlm)
summary(pca_hlm_model2)
#becomes singular: not recommended

################################
#                              #
#  Convert to IRT ready files  #
#                              #
################################


###############
# Prepping CCI ################################
###############

cci_columns_to_check <- c("pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10", "pre_11", "pre_12",
                          "pre_13", "pre_14", "pre_15", "pre_16", "pre_17", "pre_18", "pre_19", "pre_20", "pre_21", "pre_22", "pre_23", 
                          "pre_24", "post_3", "post_4", "post_5", "post_6", "post_7", "post_8", "post_9", "post_10", 
                          "post_11", "post_12", "post_13", "post_14", "post_15", "post_16", "post_17", "post_18", "post_19", "post_20", 
                          "post_21", "post_22", "post_23", "post_24")

cci_data <- cci_data %>% mutate(across(all_of(cci_columns_to_check), tolower))

###############
# GRADING CCI ################################
###############


#load key to grade CCI responses
cci_pre_key <- c(pre_3="e",pre_4="e",pre_5="a",pre_6="e",pre_7="c",pre_8="c",pre_9="b",pre_10="e",pre_11="b",pre_12="a",pre_13="b",pre_14="a",pre_15="a",pre_16="d",pre_17="c",
                pre_18="a",pre_19="b",pre_20="a",pre_21="d",pre_22="c",pre_23="a",pre_24="a")

cci_post_key <- c(post_3="e",post_4="e",post_5="a",post_6="e",post_7="c",post_8="c",post_9="b",post_10="e",post_11="b",post_12="a",post_13="b",post_14="a",post_15="a",post_16="d",post_17="c",
                 post_18="a",post_19="b",post_20="a",post_21="d",post_22="c",post_23="a",post_24="a")



cci_binary <- cci_data %>% mutate(across(matches("^pre_\\d{1,2}$"), ~ as.integer(. == cci_pre_key[cur_column()])))
cci_binary <- cci_binary %>% mutate(across(matches("^post_\\d{1,2}$"), ~ as.integer(. == cci_post_key[cur_column()])))

#setting up stuff for IRT
pre_cols_cci  <- c("pre_3","pre_4","pre_5","pre_6","pre_7","pre_8","pre_9","pre_10","pre_11","pre_12", "pre_13","pre_14",
                   "pre_15","pre_16","pre_17","pre_18","pre_19","pre_20","pre_21","pre_22","pre_23","pre_24")
post_cols_cci <- c("post_3","post_4","post_5","post_6","post_7","post_8","post_9","post_10","post_11","post_12", "post_13","post_14",
                   "post_15","post_16","post_17","post_18","post_19","post_20","post_21","post_22","post_23","post_24")

cci_clean <- cci_binary %>%
  mutate(
    # If pre_score is NA, blank out all pre item responses for that row
    across(all_of(pre_cols_cci),  ~ replace(.x, is.na(pre_score), NA)),
    
    # If post_score is NA, blank out all post item responses for that row
    across(all_of(post_cols_cci), ~ replace(.x, is.na(post_score), NA))
  )

cci_clean <- cci_clean %>% filter(!(is.na(pre_score) & is.na(post_score)))


dat_cci  <- cci_clean %>% select(student_id, all_of(pre_cols_cci), all_of(post_cols_cci))
id_vec_cci <- dat_cci$student_id
X_cci <- dat_cci %>% select(-student_id)
X_cci[] <- lapply(X_cci, function(z) { z <- as.numeric(z); ifelse(is.na(z), NA, as.integer(z)) })

J_cci <- length(pre_cols_cci)
long_model_cci <- mirt.model(paste0(
  "F1 = 1-", J_cci, "\n",
  "F2 = ", J_cci+1, "-", 2*J_cci, "\n",
  "COV = F1*F2"
))



###############
# Prepping CCA ################################
###############
#CCA
#These need to be graded
#superfluous questions need to be removed (see below)
#we need to fix the case of responses

cca_columns_to_check <- c("pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10", "pre_11",
                          "pre_13", "pre_14", "pre_15", "pre_16", "pre_17", "pre_18", "post_1", "post_2", "post_3", 
                          "post_4", "post_5", "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_13",
                          "post_14", "post_15", "post_16", "post_17", "post_18")

cca_data <- cca_data %>% mutate(across(all_of(cca_columns_to_check), tolower))


#cca_pre <- cca_data %>% select(matches("^pre_\\d{1,2}$")) %>% rename_with(~ sub("^pre_", "q", .), starts_with("pre_"))
#cca_post <- cca_data %>% select(matches("^post_\\d{1,2}$")) %>% rename_with(~ sub("^post_", "q", .), starts_with("post_"))



###############
# GRADING CCA ################################
###############

#load key to grade CCA responses
cca_pre_key <- c(pre_1="b",pre_2="b",pre_3="b",pre_4="c",pre_5="a",pre_6="c",pre_7="d",pre_8="c",pre_9="b",pre_10="d",pre_11="b", pre_13="d",pre_14="b",pre_15="b",
                 pre_16="d",pre_17="a",pre_18="c")

cca_post_key <- c(post_1="b",post_2="b",post_3="b",post_4="c",post_5="a",post_6="c",post_7="d",post_8="c",post_9="b",post_10="d",post_11="b", post_13="d",post_14="b",post_15="b",
                  post_16="d",post_17="a",post_18="c")

cca_binary <- cca_data %>% mutate(across(matches("^pre_\\d{1,2}$"), ~ as.integer(. == cca_pre_key[cur_column()])))
cca_binary <- cca_binary %>% mutate(across(matches("^post_\\d{1,2}$"), ~ as.integer(. == cca_post_key[cur_column()])))
#cca_post_binary <- cca_post %>% mutate(across(matches("^q\\d{1,2}$"), ~ as.integer(. == cca_key[cur_column()])))
#cca_pre_binary <- cca_pre %>% mutate(across(matches("^q\\d{1,2}$"), ~ as.integer(. == cca_key[cur_column()])))

#setting up stuff for IRT
pre_cols_cca  <- c("pre_1","pre_2","pre_3","pre_4","pre_5","pre_6","pre_7","pre_8","pre_9","pre_10","pre_11","pre_13","pre_14",
                   "pre_15","pre_16","pre_17","pre_18")
post_cols_cca <- c("post_1","post_2","post_3","post_4","post_5","post_6","post_7","post_8","post_9","post_10","post_11","post_13","post_14",
                   "post_15","post_16","post_17","post_18")

cca_clean <- cca_binary %>%
  mutate(
    # If pre_score is NA, blank out all pre item responses for that row
    across(all_of(pre_cols_cca),  ~ replace(.x, is.na(pre_score), NA)),
    
    # If post_score is NA, blank out all post item responses for that row
    across(all_of(post_cols_cca), ~ replace(.x, is.na(post_score), NA))
  )

cca_clean <- cca_clean %>% filter(!(is.na(pre_score) & is.na(post_score)))


dat_cca  <- cca_clean %>% select(student_id, all_of(pre_cols_cca), all_of(post_cols_cca))
id_vec_cca <- dat_cca$student_id
X_cca <- dat_cca %>% select(-student_id)
X_cca[] <- lapply(X_cca, function(z) { z <- as.numeric(z); ifelse(is.na(z), NA, as.integer(z)) })

J_cca <- length(pre_cols_cca)
long_model_cca <- mirt.model(paste0(
  "F1 = 1-", J_cca, "\n",
  "F2 = ", J_cca+1, "-", 2*J_cca, "\n",
  "COV = F1*F2"
))






###############
# Preparing PCA ################################
###############

#need to remove filtered responses

# Grab all pre/post item columns robustly
pre_cols  <- grep("^pre_\\d+_C$",  names(pca_data), value = TRUE)
post_cols <- grep("^post_\\d+_C$", names(pca_data), value = TRUE)

pca_clean <- pca_data %>%
  mutate(
    # If pre_score is NA, blank out all pre item responses for that row
    across(all_of(pre_cols),  ~ replace(.x, is.na(pre_score), NA)),
    
    # If post_score is NA, blank out all post item responses for that row
    across(all_of(post_cols), ~ replace(.x, is.na(post_score), NA))
  )

pca_clean <- pca_clean %>% filter(!(is.na(pre_score) & is.na(post_score)))


# --- 1) Columns & data matrix (PCA) ---
pre_cols_pca  <- paste0("pre_",  1:25, "_C")
post_cols_pca <- paste0("post_", 1:25, "_C")

dat_pca  <- pca_clean %>% select(student_id, all_of(pre_cols_pca), all_of(post_cols_pca))
id_vec_pca <- dat_pca$student_id
X_pca <- dat_pca %>% select(-student_id)
X_pca[] <- lapply(X_pca, function(z) { z <- as.numeric(z); ifelse(is.na(z), NA, as.integer(z)) })

J_pca <- length(pre_cols_pca)
long_model_pca <- mirt.model(paste0(
  "F1 = 1-", J_pca, "\n",
  "F2 = ", J_pca+1, "-", 2*J_pca, "\n",
  "COV = F1*F2"
))

################################
#                              #
#        3PL IRT               #
#                              #
################################

###########
# PCA IRT #
###########


# --- 2) Invariant 3PL (equal a, d, g pre=post) with Beta prior on guessing ---
vals_pca <- mirt(data = X_pca, model = long_model_pca, itemtype = "3PL", pars = "values")

find_par_pca <- function(values, item_name, par)
  which(values$item == item_name & values$name == par)

cnstr_pca <- list()
for (j in seq_len(J_pca)) {
  ipre_pca  <- pre_cols_pca[j]; ipost_pca <- post_cols_pca[j]
  cnstr_pca[[length(cnstr_pca)+1]] <- c(find_par_pca(vals_pca, ipre_pca,  "a1"),
                                        find_par_pca(vals_pca, ipost_pca, "a2"))
  cnstr_pca[[length(cnstr_pca)+1]] <- c(find_par_pca(vals_pca, ipre_pca,  "d"),
                                        find_par_pca(vals_pca, ipost_pca, "d"))
  cnstr_pca[[length(cnstr_pca)+1]] <- c(find_par_pca(vals_pca, ipre_pca,  "g"),
                                        find_par_pca(vals_pca, ipost_pca, "g"))
}

# mild prior on guessing to stabilize 3PL (tune as needed)
vals_pca$prior.type <- NA; vals_pca$prior_1 <- NA; vals_pca$prior_2 <- NA
for (nm_pca in c(pre_cols_pca, post_cols_pca)) {
  g_row_pca <- find_par_pca(vals_pca, nm_pca, "g")
  vals_pca$prior.type[g_row_pca] <- "beta"
  vals_pca$prior_1[g_row_pca]    <- 5
  vals_pca$prior_2[g_row_pca]    <- 17
}

fit_3pl_inv_pca <- mirt(
  data      = X_pca,
  model     = long_model_pca,
  itemtype  = "3PL",
  values    = vals_pca,
  constrain = cnstr_pca,
  SE        = TRUE,
  method    = "MHRM",
  technical = list(NCYCLES = 3000)
)

# --- 3) Scores & correlations (PCA) ---
ths_pca <- fscores(fit_3pl_inv_pca, method = "EAP")
theta_df_pca <- data.frame(
  student_id = id_vec_pca,
  theta_pre  = ths_pca[, "F1"],
  theta_post = ths_pca[, "F2"]
) %>% dplyr::mutate(d_theta = theta_post - theta_pre)

C_pca      <- coef(fit_3pl_inv_pca, simplify = TRUE)$cov
r_model_pca <- C_pca[1,2] / sqrt(C_pca[1,1]*C_pca[2,2])
r_eap_pca   <- cor(theta_df_pca$theta_pre, theta_df_pca$theta_post, use = "pairwise.complete.obs")

# --- 4) Visuals (PCA) ---
ggplot(theta_df_pca, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "PCA (3PL invariant): Pre vs Post ability",
       subtitle = paste0("r_model = ", round(r_model_pca,3), " | r_EAP = ", round(r_eap_pca,3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()

ggplot(theta_df_pca, aes(d_theta)) +
  geom_histogram(bins = 30) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "Change in ability (Post – Pre) — PCA",
       x = expression(Delta*theta), y = "Count") +
  theme_minimal()

#plot complete case only:

# which columns are pre vs post in X_pca
cols_pre  <- 1:J_pca
cols_post <- (J_pca + 1):(2*J_pca)

# complete-case mask based on observed responses, not on thetas
has_pre  <- rowSums(!is.na(X_pca[, cols_pre,  drop = FALSE]))  > 0
has_post <- rowSums(!is.na(X_pca[, cols_post, drop = FALSE])) > 0
cc_mask  <- has_pre & has_post

theta_df_pca_cc <- theta_df_pca[cc_mask, , drop = FALSE]
r_eap_pca_cc <- cor(theta_df_pca_cc$theta_pre, theta_df_pca_cc$theta_post)

ggplot(theta_df_pca_cc, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "PCA (3PL invariant): Pre vs Post ability (complete cases)",
       subtitle = paste0("r_EAP (complete cases) = ", round(r_eap_pca_cc, 3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()


# (Optional) overall fit (PCA)
M2(fit_3pl_inv_pca)

cf_pca <- coef(fit_3pl_inv_pca, IRTpars = TRUE, simplify = TRUE)$items

cf_pca <- as.data.frame(cf_pca)

cf_pca <- cf_pca %>% dplyr::mutate(a1 = round(as.numeric(a1),3),
                         b = round(as.numeric(b),3),
                         g = round(as.numeric(g),3))

write.csv(cf_pca, "cf_pca.csv")

#graphing parameter values

# 2×2 histograms for cf_pca (a1, b, g)
op <- par(mfrow = c(2,2), mar = c(4,4,2,1), oma = c(0,0,2,0))

hist(cf_pca$a1, breaks = "FD", col = "gray",
     main = "Discrimination (a1)", xlab="")
abline(v = median(cf_pca$a1, na.rm = TRUE), lty = 2)

hist(cf_pca$b, breaks = "FD", col = "gray",
     main = "Difficulty (b)", xlab="")
abline(v = median(cf_pca$b, na.rm = TRUE), lty = 2)

hist(cf_pca$g, breaks = "FD", col = "gray",
     main = "Guessing (g)", xlab="")
abline(v = median(cf_pca$g, na.rm = TRUE), lty = 2)

mtext("PCA 3PL Item Parameters — 2×2 Histograms", outer = TRUE, cex = 1.1)
par(op)

#missingness
temp_pca <- pca_clean
temp_pca <- temp_pca %>% select(-male, -female, -parent_degree, -gains)
aggr(temp_pca)




###########
# CCA IRT #
###########


# --- 2) Invariant 3PL (equal a, d, g pre=post) with Beta prior on guessing ---
vals_cca <- mirt(data = X_cca, model = long_model_cca, itemtype = "3PL", pars = "values")

find_par_cca <- function(values, item_name, par)
  which(values$item == item_name & values$name == par)

cnstr_cca <- list()
for (j in seq_len(J_cca)) {
  ipre_cca  <- pre_cols_cca[j]; ipost_cca <- post_cols_cca[j]
  cnstr_cca[[length(cnstr_cca)+1]] <- c(find_par_cca(vals_cca, ipre_cca,  "a1"),
                                        find_par_cca(vals_cca, ipost_cca, "a2"))
  cnstr_cca[[length(cnstr_cca)+1]] <- c(find_par_cca(vals_cca, ipre_cca,  "d"),
                                        find_par_cca(vals_cca, ipost_cca, "d"))
  cnstr_cca[[length(cnstr_cca)+1]] <- c(find_par_cca(vals_cca, ipre_cca,  "g"),
                                        find_par_cca(vals_cca, ipost_cca, "g"))
}

# mild prior on guessing to stabilize 3PL (tune as needed)
vals_cca$prior.type <- NA; vals_cca$prior_1 <- NA; vals_cca$prior_2 <- NA
for (nm_cca in c(pre_cols_cca, post_cols_cca)) {
  g_row_cca <- find_par_cca(vals_cca, nm_cca, "g")
  vals_cca$prior.type[g_row_cca] <- "beta"
  vals_cca$prior_1[g_row_cca]    <- 5
  vals_cca$prior_2[g_row_cca]    <- 17
}

fit_3pl_inv_cca <- mirt(
  data      = X_cca,
  model     = long_model_cca,
  itemtype  = "3PL",
  values    = vals_cca,
  constrain = cnstr_cca,
  SE        = TRUE,
  method    = "MHRM",
  technical = list(NCYCLES = 3000)
)

# --- 3) Scores & correlations (CCA) ---
ths_cca <- fscores(fit_3pl_inv_cca, method = "MAP")
theta_df_cca <- data.frame(
  student_id = id_vec_cca,
  theta_pre  = ths_cca[, "F1"],
  theta_post = ths_cca[, "F2"]
) %>% dplyr::mutate(d_theta = theta_post - theta_pre)

C_cca      <- coef(fit_3pl_inv_cca, simplify = TRUE)$cov
r_model_cca <- C_cca[1,2] / sqrt(C_cca[1,1]*C_cca[2,2])
r_eap_cca   <- cor(theta_df_cca$theta_pre, theta_df_cca$theta_post, use = "pairwise.complete.obs")

# --- 4) Visuals (CCA) ---
ggplot(theta_df_cca, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "CCA (3PL invariant): Pre vs Post ability",
       subtitle = paste0("r_model = ", round(r_model_cca,3), " | r_EAP = ", round(r_eap_cca,3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()

ggplot(theta_df_cca, aes(d_theta)) +
  geom_histogram(bins = 30) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "Change in ability (Post – Pre) — CCA",
       x = expression(Delta*theta), y = "Count") +
  theme_minimal()

# (Optional) overall fit (CCA)
M2(fit_3pl_inv_cca)

#plot complete case only:

# which columns are pre vs post in X_cca
cols_pre  <- 1:J_cca
cols_post <- (J_cca + 1):(2*J_cca)

# complete-case mask based on observed responses, not on thetas
has_pre  <- rowSums(!is.na(X_cca[, cols_pre,  drop = FALSE]))  > 0
has_post <- rowSums(!is.na(X_cca[, cols_post, drop = FALSE])) > 0
cc_mask  <- has_pre & has_post

theta_df_cca_cc <- theta_df_cca[cc_mask, , drop = FALSE]
r_eap_cca_cc <- cor(theta_df_cca_cc$theta_pre, theta_df_cca_cc$theta_post)

ggplot(theta_df_cca_cc, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "CCA (3PL invariant): Pre vs Post ability (complete cases)",
       subtitle = paste0("r_EAP (complete cases) = ", round(r_eap_cca_cc, 3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()



cf_cca <- coef(fit_3pl_inv_cca, IRTpars = TRUE, simplify = TRUE)$items

cf_cca <- as.data.frame(cf_cca)

cf_cca <- cf_cca %>% dplyr::mutate(a1 = round(as.numeric(a1),3),
                                   b = round(as.numeric(b),3),
                                   g = round(as.numeric(g),3))

write.csv(cf_cca, "cf_cca.csv")

#graphing parameter values

# 2×2 histograms for cf_cca (a1, b, g)
op <- par(mfrow = c(2,2), mar = c(4,4,2,1), oma = c(0,0,2,0))

hist(cf_cca$a1, breaks = "FD", col = "gray",
     main = "Discrimination (a1)", xlab="")
abline(v = median(cf_cca$a1, na.rm = TRUE), lty = 2)

hist(cf_cca$b, breaks = "FD", col = "gray",
     main = "Difficulty (b)", xlab="")
abline(v = median(cf_cca$b, na.rm = TRUE), lty = 2)

hist(cf_cca$g, breaks = "FD", col = "gray",
     main = "Guessing (g)", xlab="")
abline(v = median(cf_cca$g, na.rm = TRUE), lty = 2)

mtext("CCA 3PL Item Parameters — 2×2 Histograms", outer = TRUE, cex = 1.1)
par(op)

#missingness
temp_cca <- cca_clean
temp_cca <- temp_cca %>% select(-male, -female, -parent_degree, -gains, -post_score)
aggr(temp_cca)











###########
# CCI IRT #
###########


# --- 2) Invariant 3PL (equal a, d, g pre=post) with Beta prior on guessing ---
vals_cci <- mirt(data = X_cci, model = long_model_cci, itemtype = "3PL", pars = "values")

find_par_cci <- function(values, item_name, par)
  which(values$item == item_name & values$name == par)

cnstr_cci <- list()
for (j in seq_len(J_cci)) {
  ipre_cci  <- pre_cols_cci[j]; ipost_cci <- post_cols_cci[j]
  cnstr_cci[[length(cnstr_cci)+1]] <- c(find_par_cci(vals_cci, ipre_cci,  "a1"),
                                        find_par_cci(vals_cci, ipost_cci, "a2"))
  cnstr_cci[[length(cnstr_cci)+1]] <- c(find_par_cci(vals_cci, ipre_cci,  "d"),
                                        find_par_cci(vals_cci, ipost_cci, "d"))
  cnstr_cci[[length(cnstr_cci)+1]] <- c(find_par_cci(vals_cci, ipre_cci,  "g"),
                                        find_par_cci(vals_cci, ipost_cci, "g"))
}

# mild prior on guessing to stabilize 3PL (tune as needed)
vals_cci$prior.type <- NA; vals_cci$prior_1 <- NA; vals_cci$prior_2 <- NA
for (nm_cci in c(pre_cols_cci, post_cols_cci)) {
  g_row_cci <- find_par_cci(vals_cci, nm_cci, "g")
  vals_cci$prior.type[g_row_cci] <- "beta"
  vals_cci$prior_1[g_row_cci]    <- 5
  vals_cci$prior_2[g_row_cci]    <- 17
}

fit_3pl_inv_cci <- mirt(
  data      = X_cci,
  model     = long_model_cci,
  itemtype  = "3PL",
  values    = vals_cci,
  constrain = cnstr_cci,
  SE        = TRUE,
  method    = "MHRM",
  technical = list(NCYCLES = 3000)
)

# --- 3) Scores & correlations (CCI) ---
ths_cci <- fscores(fit_3pl_inv_cci, method = "EAP")
theta_df_cci <- data.frame(
  student_id = id_vec_cci,
  theta_pre  = ths_cci[, "F1"],
  theta_post = ths_cci[, "F2"]
) %>% dplyr::mutate(d_theta = theta_post - theta_pre)

C_cci      <- coef(fit_3pl_inv_cci, simplify = TRUE)$cov
r_model_cci <- C_cci[1,2] / sqrt(C_cci[1,1]*C_cci[2,2])
r_eap_cci   <- cor(theta_df_cci$theta_pre, theta_df_cci$theta_post, use = "pairwise.complete.obs")

# --- 4) Visuals (CCI) ---
ggplot(theta_df_cci, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "CCI (3PL invariant): Pre vs Post ability",
       subtitle = paste0("r_model = ", round(r_model_cci,3), " | r_EAP = ", round(r_eap_cci,3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()

ggplot(theta_df_cci, aes(d_theta)) +
  geom_histogram(bins = 30) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "Change in ability (Post – Pre) — CCI",
       x = expression(Delta*theta), y = "Count") +
  theme_minimal()

# (Optional) overall fit (CCI)
M2(fit_3pl_inv_cci)



#plot complete case only:

# which columns are pre vs post in X_cci
cols_pre  <- 1:J_cci
cols_post <- (J_cci + 1):(2*J_cci)

# complete-case mask based on observed responses, not on thetas
has_pre  <- rowSums(!is.na(X_cci[, cols_pre,  drop = FALSE]))  > 0
has_post <- rowSums(!is.na(X_cci[, cols_post, drop = FALSE])) > 0
cc_mask  <- has_pre & has_post

theta_df_cci_cc <- theta_df_cci[cc_mask, , drop = FALSE]
r_eap_cci_cc <- cor(theta_df_cci_cc$theta_pre, theta_df_cci_cc$theta_post)

ggplot(theta_df_cci_cc, aes(theta_pre, theta_post)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(title = "CCI (3PL invariant): Pre vs Post ability (complete cases)",
       subtitle = paste0("r_EAP (complete cases) = ", round(r_eap_cci_cc, 3)),
       x = expression(theta[pre]), y = expression(theta[post])) +
  theme_minimal()



cf_cci <- coef(fit_3pl_inv_cci, IRTpars = TRUE, simplify = TRUE)$items

cf_cci <- as.data.frame(cf_cci)

cf_cci <- cf_cci %>% dplyr::mutate(a1 = round(as.numeric(a1),3),
                                   b = round(as.numeric(b),3),
                                   g = round(as.numeric(g),3))

write.csv(cf_cci, "cf_cci.csv")

#graphing parameter values

# 2×2 histograms for cf_cci (a1, b, g)
op <- par(mfrow = c(2,2), mar = c(4,4,2,1), oma = c(0,0,2,0))

hist(cf_cci$a1, breaks = "FD", col = "gray",
     main = "Discrimination (a1)", xlab="")
abline(v = median(cf_cci$a1, na.rm = TRUE), lty = 2)

hist(cf_cci$b, breaks = "FD", col = "gray",
     main = "Difficulty (b)", xlab="")
abline(v = median(cf_cci$b, na.rm = TRUE), lty = 2)

hist(cf_cci$g, breaks = "FD", col = "gray",
     main = "Guessing (g)", xlab="")
abline(v = median(cf_cci$g, na.rm = TRUE), lty = 2)

mtext("CCI 3PL Item Parameters — 2×2 Histograms", outer = TRUE, cex = 1.1)
par(op)

#missingness
temp_cci <- cci_clean
temp_cci <- temp_cci %>% select(-male, -female, -parent_degree, -gains, -post_score)
aggr(temp_cci)





################################
#                              #
#       Sankey Diagrams        #
#                              #
################################

#########
#       #
#  PCA  #
#       #
#########


#prep the data for GDINA
pca_clean_pre <- pca_clean %>% select(starts_with("pre_")) %>% select(-pre_score)
pca_clean_pre <- pca_clean_pre %>% rename_with(
                                      ~ str_replace(.x, "^pre_([0-9]{1,2})_C$", "q\\1"),
                                      matches("^pre_[0-9]{1,2}_C$"))

pca_clean_post <- pca_clean %>% select(starts_with("post_")) %>% select(-post_score)
pca_clean_post <- pca_clean_post %>% rename_with(
                                      ~ str_replace(.x, "^post_([0-9]{1,2})_C$", "q\\1"),
                                      matches("^post_[0-9]{1,2}_C$"))

#Here is what chappy helps:
#not sure what this does yet
#not sure what this does yet
pre_missing_idx_pca  <- apply(pca_clean_pre,  1, function(x) all(is.na(x)))
post_missing_idx_pca <- apply(pca_clean_post, 1, function(x) all(is.na(x)))

#load the q-matrix
Q_pca <- read_excel("Qmatrix.xlsx", sheet= "pca")
Q_pca <- Q_pca %>% dplyr::select(-LO, -D)

fit_pre_pca  <- GDINA::GDINA(dat = pca_clean_pre,  Q = Q_pca,  model = "GDINA")
fit_post_pca <- GDINA::GDINA(dat = pca_clean_post, Q = Q_pca, model = "GDINA")

# Get person-level profile summaries (choose EAP/MAP/MLE to taste)
# personparm() can return attribute estimates and/or latent-class posteriors
pre_pp_pca  <- GDINA::personparm(fit_pre_pca)   # check $att.est (attributes) and/or $LC.prob (profiles)
post_pp_pca <- GDINA::personparm(fit_post_pca)



get_att_from_fit <- function(fit) {
  att <- tryCatch(GDINA::personparm(fit, what = "EAP"), error = function(e) NULL)
  if (is.null(att)) att <- tryCatch(GDINA::personparm(fit, what = "att.est"), error = function(e) NULL)
  if (is.null(att)) stop("Couldn't extract EAP/att.est from fit.")
  att <- as.matrix(att)
  if (length(dim(att)) == 0L) att <- matrix(att, ncol = 1) # handle K=1
  att
}

pre_att_pca  <- get_att_from_fit(fit_pre_pca)
post_att_pca <- get_att_from_fit(fit_post_pca)

# binarize (EAP->0/1); tweak cutoff if you prefer MAP-like strictness
pre_bin_pca  <- ifelse(pre_att_pca  >= 0.5, 1L, 0L)
post_bin_pca <- ifelse(post_att_pca >= 0.5, 1L, 0L)

att_to_label <- function(v) if (all(is.na(v))) NA_character_ else paste0(v, collapse = "")

#(Mike 7/22/26) There is an error here: GDINA drops respondents with <=1
#valid item response, so pre_bin_pca/post_bin_pca (and therefore
#pre_label_pca/post_label_pca below) can be shorter than pca_clean_pre/
#pca_clean_post. The missingness-index assignments and bind_cols() just
#below assume matching lengths and silently misalign rather than erroring
#(unlike the CCA/CCI versions of this bug, which do error). This has been
#corrected in IJRUME_analysis.Rmd (see make_profile_labels()), which
#re-aligns GDINA's retained rows back to the full sample before combining
#pre/post profiles.
pre_label_pca  <- apply(pre_bin_pca,  1, att_to_label)
post_label_pca <- apply(post_bin_pca, 1, att_to_label)


# Overwrite labels for truly missing tests
pre_label_pca[pre_missing_idx_pca]   <- "Missing"
post_label_pca[post_missing_idx_pca] <- "Missing"

pre_label_pca[is.na(pre_label_pca) & !pre_missing_idx_pca]   <- "Uncertain"
post_label_pca[is.na(post_label_pca) & !post_missing_idx_pca] <- "Uncertain"

pca_profiles_sankey <- bind_cols(pre_label_pca, post_label_pca)
pca_profiles_sankey <- pca_profiles_sankey %>% mutate(
  pre_class = pre_label_pca,
  #pre_class = paste0(latent_class_pre," (pre)"),
  post_class = paste0(post_label_pca, " ")
  
)
pca_profiles_sankey <- pca_profiles_sankey %>% dplyr::select(pre_class, post_class)

pca_df <- pca_profiles_sankey

#trying to get counts to filter

temp_pca <- pca_profiles_sankey

#bunch of stuff to make sure there are no groups smaller than 10
pre_count_pca <- temp_pca %>% count(pre_class) %>% rename(n_pre = n)
post_count_pca <- temp_pca %>% count(post_class) %>% rename(n_post = n)
temp_pca <- temp_pca %>% left_join(pre_count_pca, by = "pre_class") %>% left_join(post_count_pca, by="post_class")
temp_pca <- temp_pca %>% filter(n_pre >= 10, n_post >=10)
temp_pca <- temp_pca %>% dplyr::select(-n_pre, -n_post)
pca_df <- temp_pca


# Re-create node list
pca_nodes <- sort(unique(c(pca_df$pre_class, pca_df$post_class)))
pca_nodes <- data.frame(name = pca_nodes)

# Count transitions
pca_transition_counts <- pca_df %>%
  count(pre_class, post_class, name = "value")

# Map names to node indexes
pca_links <- pca_transition_counts %>%
  mutate(
    source = match(pre_class, pca_nodes$name) - 1,
    target = match(post_class, pca_nodes$name) - 1
  ) %>%
  dplyr::select(source, target, value)

# Draw Sankey
pca_sankey_plot<- sankeyNetwork(
  Links = pca_links,
  Nodes = pca_nodes,
  Source = "source",
  Target = "target",
  Value = "value",
  NodeID = "name",
  fontSize = 20,
  nodeWidth = 50,
  width = 800
)
pca_sankey_plot

#########
#       #
#  CCA  #
#       #
#########

Q_cca <- read_excel("Qmatrix.xlsx", sheet= "cca")
Q_cca <- Q_cca %>% dplyr::select(-LO)

#prep the item-level binary data for GDINA (cca_pre/cca_post were earlier
#bound to single-column score summaries above; rebuild them here as the
#q1..q17 response matrices GDINA needs, in the same item order as Q_cca)
cca_pre <- cca_binary %>% select(starts_with("pre_")) %>% select(-pre_score)
cca_pre <- cca_pre %>% rename_with(
                                      ~ str_replace(.x, "^pre_([0-9]{1,2})$", "q\\1"),
                                      matches("^pre_[0-9]{1,2}$"))

cca_post <- cca_binary %>% select(starts_with("post_")) %>% select(-post_score)
cca_post <- cca_post %>% rename_with(
                                      ~ str_replace(.x, "^post_([0-9]{1,2})$", "q\\1"),
                                      matches("^post_[0-9]{1,2}$"))

#DINA models
pre_cca_dina <- GDINA(dat = cca_pre, Q = Q_cca, model = "DINA")
post_cca_dina <- GDINA(dat = cca_post, Q = Q_cca, model = "DINA")

#(Mike 7/22/26) There is an error here: GDINA drops respondents with <=1
#valid item response (independently for pre and post), so
#cca_pre_skillprofile and cca_post_skillprofile can end up with different
#row counts. bind_cols() below then throws "Can't recycle ... to match ..."
#and the script halts -- confirmed when I re-ran this file (1092
#respondents were dropped from one side but not the other). This has been
#corrected in IJRUME_analysis.Rmd (see make_profile_labels()), which
#re-aligns GDINA's retained rows back to the full sample before combining
#pre/post profiles.
cca_pre_skillprofile <- personparm(pre_cca_dina, what = "MAP")
cca_pre_skillprofile <- cca_pre_skillprofile %>% dplyr::select(-multimodes)
cca_pre_skillprofile$latent_class_pre <- apply(cca_pre_skillprofile, 1, function(row) paste0(row, collapse = ""))
cca_pre_skillprofile <- cca_pre_skillprofile %>% dplyr::select(-c("A1","A2", "A3", "A4", "A5"))


cca_post_skillprofile <- personparm(post_cca_dina, what = "MAP")
cca_post_skillprofile <- cca_post_skillprofile %>% dplyr::select(-multimodes)
cca_post_skillprofile$latent_class_post <- apply(cca_post_skillprofile, 1, function(row) paste0(row, collapse = ""))
cca_post_skillprofile <- cca_post_skillprofile %>% dplyr::select(-c("A1","A2", "A3", "A4", "A5"))


cca_profiles_sankey <- bind_cols(cca_pre_skillprofile,cca_post_skillprofile)
cca_profiles_sankey <- cca_profiles_sankey %>% mutate(
  pre_class = latent_class_pre,
  #pre_class = paste0(latent_class_pre," (pre)"),
  post_class = paste0(latent_class_post, " ")
  
)
cca_profiles_sankey <- cca_profiles_sankey %>% dplyr::select(-latent_class_pre, -latent_class_post)

cca_df <- cca_profiles_sankey

#trying to get counts to filter

temp_cca <- cca_profiles_sankey

#bunch of stuff to make sure there are no groups smaller than 10
pre_count_cca <- temp_cca %>% count(pre_class) %>% rename(n_pre = n)
post_count_cca <- temp_cca %>% count(post_class) %>% rename(n_post = n)
temp_cca <- temp_cca %>% left_join(pre_count_cca, by = "pre_class") %>% left_join(post_count_cca, by="post_class")
temp_cca <- temp_cca %>% filter(n_pre >= 10, n_post >=10)
temp_cca <- temp_cca %>% dplyr::select(-n_pre, -n_post)
cca_df <- temp_cca


# Re-create node list
cca_nodes <- sort(unique(c(cca_df$pre_class, cca_df$post_class)))
cca_nodes <- data.frame(name = cca_nodes)

# Count transitions
cca_transition_counts <- cca_df %>%
  count(pre_class, post_class, name = "value")

# Map names to node indexes
cca_links <- cca_transition_counts %>%
  mutate(
    source = match(pre_class, cca_nodes$name) - 1,
    target = match(post_class, cca_nodes$name) - 1
  ) %>%
  dplyr::select(source, target, value)

# Draw Sankey
cca_sankey_plot<- sankeyNetwork(
  Links = cca_links,
  Nodes = cca_nodes,
  Source = "source",
  Target = "target",
  Value = "value",
  NodeID = "name",
  fontSize = 20,
  nodeWidth = 30,
  width = 408
)
cca_sankey_plot





#########
#       #
#  CCI  #
#       #
#########


Q_cci <- read_excel("Qmatrix.xlsx", sheet= "cci")
Q_cci <- Q_cci %>% dplyr::select(-LO)

#prep the item-level binary data for GDINA (cci_pre_binary/cci_post_binary
#were referenced below but never defined; build them here from cci_clean,
#in the same item order as Q_cci)
cci_pre_binary <- cci_clean %>% select(starts_with("pre_")) %>% select(-pre_score)
cci_pre_binary <- cci_pre_binary %>% rename_with(
                                      ~ str_replace(.x, "^pre_([0-9]{1,2})$", "q\\1"),
                                      matches("^pre_[0-9]{1,2}$"))

cci_post_binary <- cci_clean %>% select(starts_with("post_")) %>% select(-post_score)
cci_post_binary <- cci_post_binary %>% rename_with(
                                      ~ str_replace(.x, "^post_([0-9]{1,2})$", "q\\1"),
                                      matches("^post_[0-9]{1,2}$"))

#DINA models
pre_cci_dina <- GDINA(dat = cci_pre_binary, Q = Q_cci, model = "DINA")
post_cci_dina <- GDINA(dat = cci_post_binary, Q = Q_cci, model = "DINA")

#(Mike 7/22/26) There is an error here, same as the CCA section above:
#GDINA drops respondents with <=1 valid item response independently for pre
#and post, so cci_pre_skillprofile/cci_post_skillprofile can end up with
#different row counts and bind_cols() below halts the script. This has been
#corrected in IJRUME_analysis.Rmd (see make_profile_labels()), which
#re-aligns GDINA's retained rows back to the full sample before combining
#pre/post profiles.
cci_pre_skillprofile <- personparm(pre_cci_dina, what = "MAP")
cci_pre_skillprofile <- cci_pre_skillprofile %>% dplyr::select(-multimodes)
cci_pre_skillprofile$latent_class_pre <- apply(cci_pre_skillprofile, 1, function(row) paste0(row, collapse = ""))
cci_pre_skillprofile <- cci_pre_skillprofile %>% dplyr::select(-c("A1","A2", "A3", "A4", "A5"))


cci_post_skillprofile <- personparm(post_cci_dina, what = "MAP")
cci_post_skillprofile <- cci_post_skillprofile %>% dplyr::select(-multimodes)
cci_post_skillprofile$latent_class_post <- apply(cci_post_skillprofile, 1, function(row) paste0(row, collapse = ""))
cci_post_skillprofile <- cci_post_skillprofile %>% dplyr::select(-c("A1","A2", "A3", "A4", "A5"))


cci_profiles_sankey <- bind_cols(cci_pre_skillprofile,cci_post_skillprofile)
cci_profiles_sankey <- cci_profiles_sankey %>% mutate(
  pre_class = latent_class_pre,
  #pre_class = paste0(latent_class_pre," (pre)"),
  post_class = paste0(latent_class_post, " ")
  
)
cci_profiles_sankey <- cci_profiles_sankey %>% dplyr::select(-latent_class_pre, -latent_class_post)

cci_df <- cci_profiles_sankey

#trying to get counts to filter

temp <- cci_profiles_sankey

#bunch of stuff to make sure there are no groups smaller than 10
pre_count <- temp %>% count(pre_class) %>% rename(n_pre = n)
post_count <- temp %>% count(post_class) %>% rename(n_post = n)
temp <- temp %>% left_join(pre_count, by = "pre_class") %>% left_join(post_count, by="post_class")
temp <- temp %>% filter(n_pre >= 10, n_post >=10)

tempp <- temp %>% group_by(post_class) %>% summarize(n=n())

temp <- temp %>% dplyr::select(-n_pre, -n_post)
cci_df <- temp

# Re-create node list
cci_nodes <- sort(unique(c(cci_df$pre_class, cci_df$post_class)))
cci_nodes <- data.frame(name = cci_nodes)


# Count transitions
cci_transition_counts <- cci_df %>%
  count(pre_class, post_class, name = "value")

# Map names to node indexes
cci_links <- cci_transition_counts %>%
  mutate(
    source = match(pre_class, cci_nodes$name) - 1,
    target = match(post_class, cci_nodes$name) - 1
  ) %>%
  dplyr::select(source, target, value)

# Draw Sankey
cci_sankey_plot<- sankeyNetwork(
  Links = cci_links,
  Nodes = cci_nodes,
  Source = "source",
  Target = "target",
  Value = "value",
  NodeID = "name",
  fontSize = 20,
  nodeWidth = 30,
  width = 408
)
cci_sankey_plot

#getting these Sankey diagrams side by side:

# 2) Save as self-contained HTML
saveWidget(pca_sankey_plot, "pca_sankey.html", selfcontained = TRUE)
saveWidget(cci_sankey_plot, "cci_sankey.html", selfcontained = TRUE)

# 3) Screenshot -> PNG (choose widths/heights that match your target size)
webshot("pca_sankey.html", file = "pca_sankey.png", vwidth = 900, vheight = 600, zoom = 2)
webshot("cci_sankey.html", file = "cci_sankey.png", vwidth = 900, vheight = 600, zoom = 2)

#
img1 <- image_read("pca_sankey.png") |> image_trim()
img2 <- image_read("cci_sankey.png") |> image_trim()

# Make their heights match
h <- max(image_info(img1)$height, image_info(img2)$height)
img1 <- image_extent(img1, geometry = paste0(image_info(img1)$width, "x", h), gravity = "center")
img2 <- image_extent(img2, geometry = paste0(image_info(img2)$width, "x", h), gravity = "center")

# 20-px white spacer
spacer <- image_blank(width = 100, height = h, color = "white")

combo <- image_append(c(img1, spacer, img2), stack = FALSE)
image_write(combo, "sankeys_side_by_side.png")


# 4) Combine side-by-side into one PNG (with a shared title if you like)
#p_left  <- ggdraw() + draw_image("pca_sankey.png")
#p_right <- ggdraw() + draw_image("cci_sankey.png")
#combined <- plot_grid(p_left, p_right, ncol = 2, rel_widths = c(1, 1))
#ggsave("sankeys_side_by_side.png", combined, width = 12, height = 5.5, dpi = 300)
